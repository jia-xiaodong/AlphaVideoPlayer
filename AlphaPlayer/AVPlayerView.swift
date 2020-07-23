//
//  AVPlayerView.swift
//  MyTransparentVideoExample
//
//  Created by Quentin on 27/10/2017.
//  Copyright © 2017 Quentin Fasquel. All rights reserved.
//

import AVFoundation
import UIKit

public typealias PlayItemLoadCallback = ((NSError?) -> Void)

public class AVPlayerView: UIView {
	
	var mItemLoadCallback: PlayItemLoadCallback?
	
    deinit {
        playerItem = nil
    }
	
    public override class func layerClass() -> AnyClass {
        return AVPlayerLayer.self
    }
    
    public var playerLayer: AVPlayerLayer {
        return layer as! AVPlayerLayer
    }

    public private(set) var player: AVPlayer? {
        set { playerLayer.player = newValue }
        get { return playerLayer.player }
    }

    private(set) var playerItem: AVPlayerItem? = nil {
        didSet {
            // If `isLoopingEnabled` is called before the AVPlayer was set
            setupLooping()
        }
    }
	
    public func loadPlayerItem(playerItem: AVPlayerItem, completionHandler: PlayItemLoadCallback? = nil) {
        let player = AVPlayer(playerItem: playerItem)

        self.player = player
        self.playerItem = playerItem

		mItemLoadCallback = completionHandler
        if completionHandler == nil {
            return
        }
		playerItem.addObserver(self, forKeyPath: "status", options: .New, context: nil)
    }
	
	public override func observeValueForKeyPath(keyPath: String?, ofObject object: AnyObject?, change: [String : AnyObject]?, context: UnsafeMutablePointer<Void>) {
		if keyPath?.compare("status") == NSComparisonResult.OrderedSame {
			let status: AVPlayerItemStatus
			if let statusNumber = change?[NSKeyValueChangeNewKey] as? NSNumber {
				status = AVPlayerItemStatus(rawValue: statusNumber.integerValue)!
			} else {
				status = .Unknown
			}
			guard let playerItem = (object as? AVPlayerItem) else {
				return
			}
			// execute specified callback closure.
			if let completionHandler = mItemLoadCallback {
				switch status {
				case .Failed:
					completionHandler(playerItem.error)
				case .ReadyToPlay:
					completionHandler(nil)
				case .Unknown:
					break
				}
				playerItem.removeObserver(self, forKeyPath: "status")
				mItemLoadCallback = nil
			}
		}
	}
	
    // MARK: - Looping Handler
	
    /// When set to `true`, the player view automatically adds an observer on its AVPlayer,
    /// and it will play again from start every time playback ends.
    /// * Warning: This will not result in a smooth video loop.
    public var isLoopingEnabled: Bool = false {
        didSet { setupLooping() }
    }
    
    private var didPlayToEndTimeObserver: NSObjectProtocol? = nil {
        willSet(newObserver) {
            // When updating didPlayToEndTimeObserver,
            // automatically remove its previous value from the Notification Center
			guard let oldObserver = didPlayToEndTimeObserver else {
				return
			}
            if oldObserver !== newObserver {
				NSNotificationCenter.defaultCenter().removeObserver(oldObserver)
            }
        }
    }
    
    private func setupLooping() {
        guard let playerItem = self.playerItem, let player = self.player else {
            return
        }
        
        guard isLoopingEnabled else {
            didPlayToEndTimeObserver = nil
            return
        }
		
		didPlayToEndTimeObserver = NSNotificationCenter.defaultCenter().addObserverForName(
			AVPlayerItemDidPlayToEndTimeNotification,
		    object: playerItem,
		    queue: nil,
			usingBlock: { _ in
				player.seekToTime(kCMTimeZero, completionHandler: { _ in
					player.play()
				})
		})
    }
}
