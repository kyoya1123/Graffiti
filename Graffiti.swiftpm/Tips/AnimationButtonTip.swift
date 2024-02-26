import TipKit

struct AnimationButtonTip: Tip {
    
    var image: Image? {
        Image(systemName: "film")
    }
    
    var title: Text {
        Text("Create Animation")
    }
    var message: Text? {
        Text("Tap this button to draw next frame")
    }
}
