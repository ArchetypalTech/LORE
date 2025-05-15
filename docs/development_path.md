# Development path

#### Stabilize for Celestia milestones

- Stabilize components (with component changes your JSON import/export changes)
- Make sure import/export works (necessary for initial milestones + storywriting) #50
  https://github.com/orgs/ArchetypalTech/projects/3?query=sort%3Aupdated-desc+is%3Aopen&pane=issue&itemId=108569105&issue=ArchetypalTech%7CLORE%7C50
- run first QA with users to find any hidden issues while writing stories
- test deployments -> branch off of main a stable `celestia` version that you can use for initial Celestia milestones + slot deployments for the QA + editor closed QA milestones
- you can deploy that using a PR or you can spin up a Railway environment for the celestia branch

#### Logic System

- Ignore dictionary editor for now- manually hardcode entries for now

Recommended for milestones is to build the simplest type of logic actions, ideally static, global

Cairo can be built out first to test the system
React editor will need to be designed out, can be built out once basic Cairo models are in place

1. Build out triggers

- use common action to build out and fire the first triggers (on player enters room, look at item), hook into existing actions

2. Build out actions struct

3. Build out effects

- create a basic effect for debugging, you're mostly interesting in reusing the triggercontext throughout the effects

4. Build out ocnditions

- create a basic condition ()

5. ...

6. ...? profit
