Feature: Catalog Data Page

  Scenario: Access catalog data and capture the view
    Given I am logged in via SSO
    When I navigate to the catalog data page
    Then I take a screenshot of the page
