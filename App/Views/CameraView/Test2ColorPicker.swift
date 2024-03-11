//
//  Test2ColorPicker.swift
//  Project-Shangri-La (iOS)
//
//  Created by Nick Doolittle on 3/27/23.
//

import SwiftUI

struct CustomColorPickerTest<Label: View>: View {
    @Binding private var selectedColor: Color
    private var label: Label
    private var supportsOpacity: Bool
    private var onDismiss: ((Color) -> Void)?
    
    @State private var isColorPickerShown = false
    
    init(selection: Binding<Color>, supportsOpacity: Bool = true, onDismiss: ((Color) -> Void)? = nil, @ViewBuilder label: () -> Label) {
        self._selectedColor = selection
        self.supportsOpacity = supportsOpacity
        self.label = label()
        self.onDismiss = onDismiss
    }
    
    var body: some View {
        Button(action: {
            isColorPickerShown = true
        }) {
            label
        }
        .fullScreenCover(isPresented: $isColorPickerShown) {
            ColorPickerViewController(selectedColor: $selectedColor, supportsOpacity: supportsOpacity, onDismiss: { color in
                isColorPickerShown = false
                onDismiss?(color) // Call the onDismiss closure with the selected color
            })
        }
    }
}

struct ColorPickerViewController: UIViewControllerRepresentable {
    @Environment(\.presentationMode) var presentationMode
    @Binding var selectedColor: Color
    var supportsOpacity: Bool
    var onDismiss: ((Color) -> Void)?
    
    func makeUIViewController(context: Context) -> UIColorPickerViewController {
        let picker = UIColorPickerViewController()
        picker.selectedColor = UIColor(selectedColor)
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIColorPickerViewController, context: Context) {
        // Update the selected color when the SwiftUI view updates
        uiViewController.selectedColor = UIColor(selectedColor)
        if supportsOpacity {
            uiViewController.selectedColor = uiViewController.selectedColor.withAlphaComponent(CGFloat(selectedColor.cgColor!.alpha))
        }
    }
    
    func makeCoordinator() -> Coordinator {
        return Coordinator(parent: self)
    }
    
    class Coordinator: NSObject, UIColorPickerViewControllerDelegate {
        var parent: ColorPickerViewController
        
        init(parent: ColorPickerViewController) {
            self.parent = parent
        }
        
        func colorPickerViewControllerDidSelectColor(_ viewController: UIColorPickerViewController) {
            let selectedColor = viewController.selectedColor
            parent.selectedColor = Color(selectedColor)
            parent.onDismiss?(Color(selectedColor)) // Call the onDismiss closure with the selected color
            parent.presentationMode.wrappedValue.dismiss()
        }
    }
}


struct ContentViewTest: View {
    @State private var selectedColor: Color = Color.white
    @State private var selectedColorText: String = ""
    
    var body: some View {
        VStack {
//            CustomColorPickerTest(selection: $selectedColor, supportsOpacity: false, onDismiss: { newColor in
//                let red = Int(newColor.components.red * 255)
//                let green = Int(newColor.components.green * 255)
//                let blue = Int(newColor.components.blue * 255)
//                let brightness = newColor.brightness.rounded()
//                selectedColorText = updateSelectedColorText(red: red, green: green, blue: blue, brightness: brightness)
//            }) {
//                Text("Pick a Color")
//                    .foregroundColor(.black)
//                    .background(selectedColor)
//                    .cornerRadius(8)
//                Spacer()
//                ZStack(alignment: .center) {
//                    Circle()
//                        .fill(AngularGradient(
//                            gradient: Gradient(colors: [.red, .purple, .blue, .cyan, Color.theme.batteryGreen, .yellow, .orange, .red]),
//                            center: .center
//                            ))
//                        .frame(height: 28)
//                    Circle()
//                        .fill(selectedColor)
//                        .frame(height: 19)
//                }
//
//            }
            ColorPicker(selection: $selectedColor) {
                HStack(alignment: .center) {
                    Text("Color Picker")
                        .foregroundColor(.primary)
                        .cornerRadius(8)
                    Text("R: \(Int(selectedColor.rgbaComponents.red * 255))")
                        .foregroundColor(Color.gray)
                        .font(.callout)
                }
            }.padding()
        }
    }
    
    func updateSelectedColorText(red: Int, green: Int, blue: Int, brightness: Double) -> String {
        return "Selected color: R:\(red) G:\(green) B:\(blue) Brightness: \(brightness)"
    }
}

struct ContentViewTest_Previews: PreviewProvider {
    static var previews: some View {
        ContentViewTest()
    }
}

