Feature: Generated app core onboarding
  The generated application should keep the starter auth and consent flows usable.

  Scenario: SSO domains show SSO login instead of password login
    Given SSO is configured for the generated app
    When I open the login page
    And I continue with an SSO email
    Then I should see the SSO login option
    And the password field should not be shown

  Scenario: Password signup sends profile details and invite token
    Given SSO is configured for the generated app
    And registration will create a pending account
    When I open the signup page
    And I continue signup with a password email
    And I complete password signup with an invite token
    Then the registration request should include profile and invite details
    And I should be on the pending approval page

  Scenario: SSO callback routes incomplete users to profile completion
    Given SSO exchange returns an incomplete generated app user
    When I return from SSO with a valid code
    Then I should be on the complete registration page

  Scenario: Cookie choices persist optional preferences only
    When I open the generated app home page
    And I reject optional cookies
    Then the saved cookie preferences should keep necessary cookies enabled
