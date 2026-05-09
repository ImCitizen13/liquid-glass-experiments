//
//  ContentView.swift
//  liquid-glass-experiments
//
//  Created by MOHAMED ELABASIRI on 08/05/2026.
//

// [orange, yellow, green, blue-green, blue, purple, pink/fushia, red]
import SwiftUI

struct MTShape: Identifiable {
    let id = UUID()
    var color: Color
    var zIndex: Double
}

enum PetalAnimation: String, CaseIterable {
        case fan        // current behavior — evenly spaced
        case bloom      // all petals fan out with overshoot
        case stack      // collapse to center
}



struct FanPetal: Shape {
    var angle: Double
    var scale: Double = 1.0
    var petalWidth: CGFloat = 60
    var petalHeight: CGFloat = 100

    var animatableData: AnimatablePair<Double, Double> {
        get { AnimatablePair(angle, scale) }
        set {
            angle = newValue.first
            scale = newValue.second
        }
    }

    func path(in rect: CGRect) -> Path {
        let scaledWidth = petalWidth * scale
        let scaledHeight = petalHeight * scale
        let ellipseRect = CGRect(
            x: rect.midX - scaledWidth / 2,
            y: rect.midY - scaledHeight,
            width: scaledWidth,
            height: scaledHeight
        )

        let cornerRadius = scaledWidth / 2
        var path = Path()
        path.addRoundedRect(in: ellipseRect, cornerSize: CGSize(width: cornerRadius, height: cornerRadius))

        let pivot = CGPoint(x: rect.midX, y: rect.midY)
        let transform = CGAffineTransform(translationX: pivot.x, y: pivot.y)
            .rotated(by: angle * .pi / 180)
            .translatedBy(x: -pivot.x, y: -pivot.y)

        return path.applying(transform)
    }
}

func getPetalValues(isOpen: Bool, petalAnimation: PetalAnimation, index: Double) -> (angle: Double, scale: Double) {
    let tempAngle = index * 45
    switch petalAnimation {
    case .fan:
        return (angle: isOpen ? tempAngle : 0, scale: 1.0)
    case .bloom:
        
        return (angle: isOpen ? tempAngle : tempAngle - 90, scale: isOpen ? 1.0 : 0.1)
    case .stack:
        return (angle: isOpen ? tempAngle : 180, scale: 1.0)
    }
}


func getAnimationCurveForAnimation(petalAnimation: PetalAnimation) -> Animation {
    // In the Toggle binding setter:
    let animation: Animation = switch petalAnimation {
        case .fan:    .spring(duration: 0.6, bounce: 0.3)        case .bloom:  .spring(duration: 1.0, bounce: 0.5)
        case .stack:  .spring(duration: 0.4, bounce: 0.1)
    }
    return animation
}

struct ControlsView: View {
    @Binding var isOpen: Bool
    @Binding var petalAnimation: PetalAnimation
    @Binding var tintOpacity: Double
    @Binding var imageName: Int
    @Binding var petalSizeFactor: Double
    var body: some View {
        GeometryReader { geo in
            VStack(spacing: 16) {
                HStack(spacing: 8){
                    Toggle(isOn: Binding(
                    get: { isOpen },
                    set: { newValue in
                        let animation = getAnimationCurveForAnimation(petalAnimation: petalAnimation)
                        withAnimation(animation) {
                            isOpen = newValue
                        }
                    }
                )) {
                    Text(isOpen ? "Collapse" : "Bloom")
                }
                .toggleStyle(.switch)
                .fixedSize()
                Picker("Animation", selection: $petalAnimation) {
                    ForEach(PetalAnimation.allCases, id: \.self) { style in
                        Text(style.rawValue.capitalized)
                    }
                }}

                Slider(value: $petalSizeFactor, in: 0.1...1.0, step: 0.1) {
                    Text("Size")
                }
                .pickerStyle(.segmented)
                Slider(value: $tintOpacity, in: 0.2...1.0, step: 0.1) {
                    Text("Tint Opacity")
                }
                
                Button {
                    imageName = (imageName >= 6) ? 1 : imageName + 1
                } label: {
                    Label("Next Image", systemImage: "arrow.triangle.2.circlepath")
                }
                .buttonStyle(.glass(.clear.tint(.black)))
            }
            .padding(24)
            .frame(width: geo.size.width * 0.8, height: geo.size.height * 0.25)
            .glassEffect(
                .clear.tint(.black.opacity(0.9)),
                in: .rect(cornerRadius: 40, style: .continuous)
            )
            .padding(30)
            .frame(width: geo.size.width, height: geo.size.height, alignment: .bottom)
        }
    }
}

struct ContentView: View {
    @State private var isOpen = false
    @State private var imageName = 1
    @State private var rotation: Double = 0
    @State private var offset: CGSize = .zero
    @State private var dragOffset: CGSize = .zero
    @State private var tintOpacity: Double = 0.7
    @State private var petalAnimation: PetalAnimation = .fan
    @State private var petalSizeFactor: Double = 1
    
    let pills: [MTShape] = [MTShape(color:.orange, zIndex: 0), MTShape(color:.yellow, zIndex: 1), MTShape(color:.green, zIndex: 2), MTShape(color:.cyan, zIndex: 3), MTShape(color:.blue, zIndex: 4), MTShape(color:.purple, zIndex: 3), MTShape(color:.pink, zIndex: 2), MTShape(color:.red, zIndex: 1)]

    var body: some View {
        ZStack(alignment: .bottom){
            ZStack {
                Image(String(imageName))
                    .resizable()
                    .scaledToFill()
                    .ignoresSafeArea()
                
                ZStack {
                    ForEach(Array(pills.enumerated()), id: \.offset) { index, pill in
                        let values = getPetalValues(isOpen: isOpen, petalAnimation: petalAnimation, index: Double(index))
                        let shape = FanPetal(angle: values.angle, scale: values.scale)
                        shape.fill(.clear)
                            .frame(width: 220, height: 220)
                            .glassEffect(.clear.tint(pill.color.opacity(tintOpacity)), in: shape)
                            
                            .onAppear{
                                let animation = getAnimationCurveForAnimation(petalAnimation: petalAnimation)
                                withAnimation(animation){
                                    isOpen = true
                                }
                            }
                    }
                }
                .frame(width: 300, height: 300)
                .scaleEffect(petalSizeFactor)
                .animation(.spring(duration: 0.4, bounce: 0.2), value: petalSizeFactor)
                .clipShape(.rect(cornerRadius: 80, style: .continuous))
                .contentShape(Rectangle())
                .offset(x: offset.width + dragOffset.width, y: offset.height + dragOffset.height)
                .gesture(
                    DragGesture()
                        .onChanged { value in
                            dragOffset = value.translation
                        }
                        .onEnded { value in
                            offset = CGSize(
                                width: offset.width + value.translation.width,
                                height: offset.height + value.translation.height
                            )
                            dragOffset = .zero
                        }
                        
                )
                
            }
            .animation(.spring(duration: 0.4, bounce: 0.3), value: offset)
            .animation(.spring(duration: 0.4, bounce: 0.3), value: dragOffset)
            ControlsView(
                isOpen: $isOpen,
                petalAnimation: $petalAnimation,
                tintOpacity: $tintOpacity,
                imageName: $imageName,
                petalSizeFactor: $petalSizeFactor
            )
        }

    }
}

#Preview {
    ContentView()
}
