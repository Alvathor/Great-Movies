//
//  AsyncImageView.swift
//  Great Movies
//
//  Created by Juliano Alvarenga on 09/03/24.
//

import SwiftUI

struct AsyncCachedImageView: View {

    @State private var image: UIImage = UIImage()
    @State private var state: OprationState = .notStarted
    private let cache = NSCache<NSString, UIImage>()
    let urlString: String
    let data: Data?
    let size: CGSize
    let aspect: ContentMode
    var body: some View {
        VStack {
            if state == .loading {
                ProgressView()
                    .frame(width: size.width, height: size.height)
            } else if state == .success || state == .notStarted {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: aspect)
                    .frame(width: size.width, height: size.height)
            } else if state == .failure {
                Button(action: {
                    Task { await fetchImage() }
                },
                       label: {
                    HStack {
                        Image(systemName: "arrow.clockwise.circle.fill")
                        Text("Retry")
                    }
                    .frame(width: size.width, height: size.height)
                    .background(.customBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                })
            }
        }
        .task { await fetchImage() }
    }

    private func fetchImage() async {
        if let url = URL(string: urlString) {
            await downloadImageFrom(from: url)
        } else if let data = data {
            self.image = UIImage(data: data)!
        }
    }
    
    // Async function to download an image
    func downloadImageFrom(from url: URL) async {

        // Check if the image is already cached
        if let cachedImage = cache.object(forKey: url.absoluteString as NSString) {
            state = .success
            image = cachedImage
        }

        do {
            state = .loading
            // Download image data
            let (data, _) = try await URLSession.shared.data(from: url)

            // Convert data to UIImage
            guard let newImage = UIImage(data: data) else {
                state = .failure
                return
            }

            // Cache the image
            cache.setObject(newImage, forKey: url.absoluteString as NSString)

            image = newImage
            state = .success
        } catch {
            state = .failure
            debugPrint("Error downloading image: \(error)")
            return
        }
    }
}
