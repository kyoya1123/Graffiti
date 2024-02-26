import TipKit

struct ARButtonTip: Tip {
    
    var image: Image? {
        Image(systemName: "arkit")
    }
    
    var title: Text {
        Text("When you done drawing")
    }
    var message: Text? {
        Text("Tap this button to toggle canvas and AR View")
    }
}
