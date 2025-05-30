Feature: End-to-End Application Flow and Verification

  Scenario: Verify the product name header on the base URL
    Given I navigate to the base URL
    Then I should see "Data Marketplace" in the product name header

 Scenario: Verify user login and toolbar elements
    Given I navigate to the base URL after login
    Then I should see "Sign out" button in the toolbar

  Scenario: Create a new listing
    Given I navigate to the Add New Listing URL
    Then I should add new listing
    And I take a screenshot of the page