Feature: HoloGraph M0/M1 walking skeleton
  The vnext workspace should prove the fixture-backed import, render, selection, focus, and recenter flow.

  Scenario: Imported GraphDocument renders and supports focused navigation
    Given the canonical HoloGraph walking skeleton fixture is available from the document API
    When I open the HoloGraph workspace
    Then the imported HoloGraph document should render
    When I select the Renderer Bridge node
    Then the Renderer Bridge details should be shown
    When I focus the selected HoloGraph node
    Then the workspace should be focused on Renderer Bridge
    When I recenter the HoloGraph workspace
    Then the whole-system HoloGraph overview should be shown
