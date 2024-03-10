//
//  AsyncImageView.swift
//  Great Movies
//
//  Created by Juliano Alvarenga on 09/03/24.
//

import SwiftUI

struct AsyncImageView: View {
    @State private var image: UIImage?
    let urlString: String
    let data: Data?
    let size: CGSize
    var body: some View {
        Group {
            if let image = image {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                    .frame(width: size.width, height: size.height)
                    .clipped()
            } else {
//                ZStack {
//                    Rectangle()
//                        .foregroundStyle(.gray)
//                        .clipShape(RoundedRectangle(cornerRadius: 20))
//                        .frame(width: size.width, height: size.height)
                    ProgressView()
                        .frame(width: size.width, height: size.height)
//                }
            }
        }
        .onAppear {
            Task {
                if let url = URL(string: urlString) {
                        self.image = await ImageLoader.shared.downloadImageFrom(from: url)
                } else if let data = data {
                    self.image = UIImage(data: data)
                }
            }
        }
    }
}


final class ImageLoader: ObservableObject {
    static let shared = ImageLoader()
    private let cache = NSCache<NSString, UIImage>()

    private init() {}

    // Load from files
    func loadImageFromPath(_ path: String) -> UIImage? {
        let fileURL = URL(fileURLWithPath: path)
        guard
            let imageData = try? Data(contentsOf: fileURL),
            let uiImage = UIImage(data: imageData)
        else {
            print("Error loading image from path: \(path)")
            return nil
        }

        return uiImage
    }

    // Async function to download an image
    func downloadImageFrom(from url: URL) async -> UIImage? {
        // Check if the image is already cached
        if let cachedImage = cache.object(forKey: url.absoluteString as NSString) {
            return cachedImage
        }

        do {
            // Download image data
            let (data, _) = try await URLSession.shared.data(from: url)

            // Convert data to UIImage
            guard let image = UIImage(data: data) else {
                return nil
            }

            // Cache the image
            cache.setObject(image, forKey: url.absoluteString as NSString)

            return image
        } catch {
            print("Error downloading image: \(error)")
            return nil
        }
    }
}
