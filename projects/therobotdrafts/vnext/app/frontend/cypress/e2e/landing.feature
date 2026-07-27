Feature: Public landing page
  The site root should pitch the product and route visitors on to the studio or an account.

  Scenario: The landing page presents the pitch and its entry points
    When I open the public landing page
    Then the product pitch and hero illustration should be shown
    And the landing page should offer the studio, sign-in, and sign-up entry points
