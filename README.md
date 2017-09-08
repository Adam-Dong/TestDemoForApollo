# TestDemoForApollo

## Environment Setup
1. Install Homebrew: `/usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"`
2. Install XCode: https://itunes.apple.com/us/app/xcode/id497799835?mt=12
3. Install git: `brew install git`
3. Install CocoaPods: `brew install cocoapods`

## Building and running
1. In the `TestDemo` directory, run `pod install` to install all the pod dependencies specified in `Podfile`. The versions specified in `Podfile.lock` file will be installed.
2. Open the `TestDemo.xcworkspace` project in XCode
3. Select the `Generic iOS Device` target
4. Ensure the project builds without errors (`Product > Build`) 
5. **TODO** Add steps for publishing and running app on device
