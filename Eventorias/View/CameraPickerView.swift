//
//  CameraPickerView.swift
//  Eventorias
//
//  Created by Sarah Maimoun on 08/10/2026.
//


import SwiftUI
import UIKit

struct CameraPickerView:
    UIViewControllerRepresentable {

    @Binding var image: UIImage?

    @Environment(\.dismiss)
    private var dismiss

    func makeCoordinator()
        -> Coordinator {

        Coordinator(
            parent: self
        )
    }

    func makeUIViewController(
        context: Context
    ) -> UIImagePickerController {

        let picker =
            UIImagePickerController()

        picker.sourceType = .camera

        picker.delegate =
            context.coordinator

        return picker
    }

    func updateUIViewController(
        _ uiViewController:
            UIImagePickerController,
        context: Context
    ) {}

    final class Coordinator:
        NSObject,
        UINavigationControllerDelegate,
        UIImagePickerControllerDelegate {

        private let parent:
            CameraPickerView

        init(
            parent: CameraPickerView
        ) {

            self.parent = parent
        }

        func imagePickerController(
            _ picker:
                UIImagePickerController,
            didFinishPickingMediaWithInfo info:
                [
                    UIImagePickerController
                        .InfoKey: Any
                ]
        ) {

            if
                let image =
                    info[
                        .originalImage
                    ] as? UIImage {

                parent.image = image
            }

            parent.dismiss()
        }

        func imagePickerControllerDidCancel(
            _ picker:
                UIImagePickerController
        ) {

            parent.dismiss()
        }
    }
}
