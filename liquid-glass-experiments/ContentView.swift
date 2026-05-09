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

struct FanPetal: Shape {
    var angle: Double
    var petalWidth: CGFloat = 60
    var petalHeight: CGFloat = 100

    var animatableData: Double {
        get { angle }
        set { angle = newValue }
    }
    
    func path(in rect: CGRect) -> Path {
        let ellipseRect = CGRect(
            x: rect.midX - petalWidth / 2,
            y: rect.midY - petalHeight,
            width: petalWidth,
            height: petalHeight
        )

        let cornerRadius = petalWidth / 2
        var path = Path()
        path.addRoundedRect(in: ellipseRect, cornerSize: CGSize(width: cornerRadius, height: cornerRadius))

        let pivot = CGPoint(x: rect.midX, y: rect.midY)
        let transform = CGAffineTransform(translationX: pivot.x, y: pivot.y)
            .rotated(by: angle * .pi / 180)
            .translatedBy(x: -pivot.x, y: -pivot.y)

        return path.applying(transform)
    }
}

struct ContentView: View {
    @State private var isOpen = true
    @State private var imageName = 1
    @State private var rotation: Double = 0
    @State private var offset: CGSize = .zero
    @State private var dragOffset: CGSize = .zero
    @State private var tintOpacity: Double = 0.7
    
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
                        let shape = FanPetal(angle: isOpen ? Double(index) * 45 : 0)
                        shape.fill(.clear)
                            .frame(width: 220, height: 220)
                            .glassEffect(.clear.tint(pill.color.opacity(tintOpacity)), in: shape)
                            .zIndex(pill.zIndex)
                            .onAppear{
                                withAnimation(.spring(duration: 0.6, bounce: 0.3)){
                                    isOpen = true
                                }
                            }
                    }
                }
                .frame(width: 300, height: 300)
                .clipShape(.rect(cornerRadius: 80, style: .continuous))
                //                .opacity(0.7)
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
            GeometryReader { geo in
                VStack(spacing: 16) {
                    Toggle(isOn: Binding(
                        get: { isOpen },
                        set: { newValue in
                            withAnimation(.spring(duration: 0.6, bounce: 0.3)) {
                                isOpen = newValue
                            }
                        }
                    )) {
                        Text(isOpen ? "Collapse" : "Bloom")
                    }
                    .toggleStyle(.switch)
                    .fixedSize()
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
                .frame(width: geo.size.width * 0.8, height: geo.size.height * 0.2)
                .glassEffect(
                    .clear.tint(.black.opacity(0.9)),
                    in: .rect(cornerRadius: 40, style: .continuous)
                ).padding(30)
                .frame(width: geo.size.width, height: geo.size.height, alignment: .bottom)
            }
        }

    }
}

#Preview {
    ContentView()
}
