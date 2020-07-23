//
//  ViewController.swift
//  AlphaPlayer
//
//  Created by jia xiaodong on 7/21/20.
//  Copyright © 2020 homemade. All rights reserved.
//

import UIKit
import Foundation		// NSBundle
import AVFoundation		// AVPlayer, ...

class ViewController: UIViewController {

	override func viewDidLoad() {
		super.viewDidLoad()
		// Do any additional setup after loading the view, typically from a nib.
		/*
		let bundle = NSBundle.mainBundle()
		let videoUrl = bundle.pathForResource("e0070_3", ofType: "mp4")
		let url = NSURL(fileURLWithPath: videoUrl!, isDirectory: false)
		let playerItem = AVPlayerItem(URL: url)
		let player = AVPlayer(playerItem: playerItem)
		let playerLayer = AVPlayerLayer(player: player)
		playerLayer.bounds = view.bounds
		playerLayer.position = view.center
		view.layer.addSublayer(playerLayer)
		player.play()
		*/
		
		let videoSize = CGSize(width: 300, height: 187)
		let playerView = AVPlayerView(frame: CGRect(origin: .zero, size: videoSize))
		view.addSubview(playerView)
		
		// Use Auto Layout anchors to center our playerView
		playerView.translatesAutoresizingMaskIntoConstraints = false
		NSLayoutConstraint.activateConstraints([
			playerView.widthAnchor.constraintEqualToConstant(videoSize.width),
			playerView.heightAnchor.constraintEqualToConstant(videoSize.height),
			playerView.centerXAnchor.constraintEqualToAnchor(view.centerXAnchor),
			playerView.centerYAnchor.constraintEqualToAnchor(view.centerYAnchor),
		])
		
		// Setup our playerLayer to hold a pixel buffer format with "alpha"
		let playerLayer: AVPlayerLayer = playerView.playerLayer
		playerLayer.pixelBufferAttributes = [
			(kCVPixelBufferPixelFormatTypeKey as String): NSNumber(unsignedInt: kCVPixelFormatType_32BGRA)]
		
		// Our AVPlayerLayer has a default backgroundColor to nil
		// Set a backgroundColor the viewController's view
		view.backgroundColor = UIColor.grayColor()
		
		// Setup looping on our video
		playerView.isLoopingEnabled = true
		
		// Load our player item
		let videoPath = NSBundle.mainBundle().pathForResource("demo", ofType: "mp4")
		let itemUrl = NSURL(fileURLWithPath: videoPath!, isDirectory: false)
		let playerItem = createTransparentItem(itemUrl)
		
		playerView.loadPlayerItem(playerItem) { [weak self] error in
			if error == nil {
				// Finally, we can start playing
				playerView.player?.play()
				// Animate background
				self?.animateBackgroundColor()
			} else {
				debugPrint("Something went wrong when loading our video: ", error?.localizedDescription)
			}
		}
	}

	override func didReceiveMemoryWarning() {
		super.didReceiveMemoryWarning()
		// Dispose of any resources that can be recreated.
	}

	// MARK: - Player Item Configuration
	
	func createTransparentItem(url: NSURL) -> AVPlayerItem {
		let asset = AVAsset(URL: url)
		let playerItem = AVPlayerItem(asset: asset)
		// Set the video so that seeking also renders with transparency
		playerItem.seekingWaitsForVideoCompositionRendering = true
		// Apply a video composition (which applies our custom filter)
		playerItem.videoComposition = createVideoComposition(for: asset)
		return playerItem
	}
	
	func createVideoComposition(for asset: AVAsset) -> AVVideoComposition {
		let filter = AlphaFrameFilter(renderingMode: .builtInFilter)
		let composition = AVMutableVideoComposition(asset: asset, applyingCIFiltersWithHandler: { request in
			do {
				let (inputImage, maskImage) = request.sourceImage.verticalSplit()
				let outputImage = try filter.process(inputImage, mask: maskImage)
				return request.finishWithImage(outputImage, context: nil)
			} catch {
				NSLog("Video composition error: %s", String(error))
				return request.finishWithError(NSError(domain: "placeholder", code: 0, userInfo: nil))
			}
		})
		
		composition.renderSize = CGSizeApplyAffineTransform(asset.videoSize, CGAffineTransformMakeScale(1.0, 0.5))
		return composition
	}
	
	// MARK: - Background Color
	
	func animateBackgroundColor() {
		let backgroundColors: [UIColor] = [.purpleColor(), .blueColor(), .cyanColor(), .greenColor(), .yellowColor(), .orangeColor(), .redColor()]

		UIView.animateWithDuration(2.0,
			delay: 0.0,
			options: .CurveLinear,
			animations: { () in
				let colorIndex = backgroundColors.indexOf(self.view.backgroundColor!) ?? 0
				let countColors = backgroundColors.count
				self.view.backgroundColor = backgroundColors[(colorIndex + 1) % countColors]},
			completion: { _ in
				self.animateBackgroundColor()
		})
	}
}

