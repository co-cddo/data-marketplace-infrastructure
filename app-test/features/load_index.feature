Feature: Load Index Page

  Scenario: Verify the product name header on the base URL
    Given I navigate to the base URL
    Then I should see "Data Marketplace" in the product name header
