defmodule ExOauth2Provider.Token.Strategy.AuthorizationCodeTest do
  use ExOauth2Provider.TestCase

  import ExOauth2Provider.Token
  import ExOauth2Provider.Test.Fixture
  import ExOauth2Provider.Test.QueryHelper
  import ExOauth2Provider.ConfigHelpers

  alias ExOauth2Provider.Token.AuthorizationCode

  @client_id          "Jf5rM8hQBc"
  @client_secret      "secret"
  @code               "code"
  @redirect_uri       "urn:ietf:wg:oauth:2.0:oob"
  @valid_request      %{"client_id" => @client_id,
                        "client_secret" => @client_secret,
                        "code" => @code,
                        "grant_type" => "authorization_code",
                        "redirect_uri" => @redirect_uri}

  @invalid_client_error %{error: :invalid_client,
                          error_description: "Client authentication failed due to unknown client, no client authentication included, or unsupported authentication method."
                        }
  @invalid_grant        %{error: :invalid_grant,
                          error_description: "The provided authorization grant is invalid, expired, revoked, does not match the redirection URI used in the authorization request, or was issued to another client."
                        }

  setup do
    resource_owner = fixture(:user)
    application = fixture(:application, fixture(:user), %{uid: @client_id, secret: @client_secret})
    {:ok, %{resource_owner: resource_owner, application: application}}
  end

  setup %{resource_owner: resource_owner, application: application} do
    access_grant = fixture(:access_grant, application, resource_owner, @code, @redirect_uri)
    {:ok, %{resource_owner: resource_owner, application: application, access_grant: access_grant}}
  end

  test "#grant/1 returns access token", %{resource_owner: resource_owner, application: application, access_grant: access_grant} do
    assert {:ok, access_token} = grant(@valid_request)
    assert access_token.access_token == get_last_access_token().token
    assert get_last_access_token().resource_owner_id == resource_owner.id
    assert get_last_access_token().application_id == application.id
    assert get_last_access_token().scopes == access_grant.scopes
    assert get_last_access_token().expires_in == ExOauth2Provider.Config.access_token_expires_in
    refute is_nil(get_last_access_token().refresh_token)
  end

  def access_token_response_body_handler(body, access_token) do
    body
    |> Map.merge(%{custom_attr: access_token.inserted_at})
  end

  test "#grant/1 returns access token with custom response handler" do
    set_config(:access_token_response_body_handler, {ExOauth2Provider.Token.Strategy.AuthorizationCodeTest, :access_token_response_body_handler})
    assert {:ok, access_token} = AuthorizationCode.grant(@valid_request)
    assert get_last_access_token().inserted_at == access_token.custom_attr
  end

  test "#grant/1 doesn't set refresh_token when ExOauth2Provider.Config.use_refresh_token? == false" do
    set_config(:use_refresh_token, false)

    assert {:ok, access_token} = AuthorizationCode.grant(@valid_request)
    assert access_token.access_token == get_last_access_token().token
    assert is_nil(get_last_access_token().refresh_token)
  end

  test "#grant/1 can't use grant twice", %{} do
    assert {:ok, _} = grant(@valid_request)
    assert {:error, %{error: :invalid_grant}, _} = grant(@valid_request)
  end

  test "#grant/1 doesn't duplicate access token", %{resource_owner: resource_owner, application: application} do
    assert {:ok, access_token} = grant(@valid_request)
    access_grant = fixture(:access_grant, application, resource_owner, "new_code", @redirect_uri)
    valid_request = Map.merge(@valid_request, %{"code" => access_grant.token})
    assert {:ok, access_token2} = grant(valid_request)
    assert access_token.access_token == access_token2.access_token
  end

  test "#grant/1 error when invalid client" do
    request_invalid_client = Map.merge(@valid_request, %{"client_id" => "invalid"})
    assert {:error, error, :unprocessable_entity} = grant(request_invalid_client)
    assert error == @invalid_client_error
  end

  test "#grant/1 error when invalid secret" do
    request_invalid_client = Map.merge(@valid_request, %{"client_secret" => "invalid"})
    assert {:error, error, :unprocessable_entity} = grant(request_invalid_client)
    assert error == @invalid_client_error
  end

  test "#grant/1 error when invalid grant" do
    request_invalid_grant = Map.merge(@valid_request, %{"code" => "invalid"})
    assert {:error, error, :unprocessable_entity} = grant(request_invalid_grant)
    assert error == @invalid_grant
  end

  test "#grant/1 error when grant owned by another client", %{access_grant: access_grant} do
    new_application = fixture(:application, fixture(:user), %{uid: "new_app"})
    changeset = Ecto.Changeset.change access_grant, application_id: new_application.id
    ExOauth2Provider.repo.update! changeset

    assert {:error, error, :unprocessable_entity} = grant(@valid_request)
    assert error == @invalid_grant
  end

  test "#grant/1 error when revoked grant", %{access_grant: access_grant} do
    changeset = Ecto.Changeset.change access_grant, revoked_at: NaiveDateTime.utc_now
    ExOauth2Provider.repo.update! changeset

    assert {:error, error, :unprocessable_entity} = grant(@valid_request)
    assert error == @invalid_grant
  end

  test "#grant/1 error when grant expired", %{access_grant: access_grant} do
    inserted_at = NaiveDateTime.utc_now |> NaiveDateTime.add(-access_grant.expires_in, :second)
    access_grant
    |> Ecto.Changeset.change(%{inserted_at: inserted_at})
    |> ExOauth2Provider.repo.update()

    assert {:error, error, :unprocessable_entity} = grant(@valid_request)
    assert error == @invalid_grant
  end

  test "#grant/1 error when grant revoked", %{access_grant: access_grant} do
    ExOauth2Provider.OauthAccessGrants.revoke(access_grant)

    assert {:error, error, :unprocessable_entity} = grant(@valid_request)
    assert error == @invalid_grant
  end

  test "#grant/1 error when invalid redirect_uri" do
    request_invalid_redirect_uri = Map.merge(@valid_request, %{"redirect_uri" => "invalid"})
    assert {:error, error, :unprocessable_entity} = grant(request_invalid_redirect_uri)
    assert error == @invalid_grant
  end
end
