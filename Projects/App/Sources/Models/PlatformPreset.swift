//
//  PlatformPreset.swift
//  App
//

import Foundation

enum PlatformPreset: String, CaseIterable {
    case instagram, twitter, tiktok, youtube

    var displayName: String {
        switch self {
        case .instagram: return "IG";
        case .twitter: return "X";
        case .tiktok: return "TikTok";
        case .youtube: return "YouTube";
        }
    }

    var characterLimit: Int {
        switch self {
        case .instagram: return 2200;
        case .twitter: return 280;
        case .tiktok: return 2200;
        case .youtube: return 500;
        }
    }

    var useHashSeparator: Bool {
        switch self {
        case .instagram, .twitter, .tiktok: return true;
        case .youtube: return false;
        }
    }

    var isPaidLocked: Bool { false; }  // all free at launch

    var limitLabel: String {
        let formatter = NumberFormatter();
        formatter.numberStyle = .decimal;
        return formatter.string(from: NSNumber(value: characterLimit)) ?? "\(characterLimit)";
    }
}
