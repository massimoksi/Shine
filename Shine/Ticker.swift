// Copyright (c) 2016 Massimo Peri (@massimoksi)
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

import Foundation

private var logger: TickerLogger?

private var minimumLogLevel = LogLevel.Debug

// MARK: Setup

public func setup(level: LogLevel = .Debug, style: LogLevelStyle = .Funny, showTimestamp: Bool = true) {
    logger = TickerLogger(levelStyle: style, showTimestamp: showTimestamp)
    minimumLogLevel = level
}

// MARK: Logging

/**
    Logs an info message on console.

    - parameter message: The info message to be logged.
*/
public func info(message: String) {
    if minimumLogLevel.hashValue >= LogLevel.Info.hashValue {
        logger?.log(message, level: .Info)
    }
}

/**
    Logs a debug message on console.

    - parameter message: The debug message to be logged.
*/
public func debug(message: String) {
    if minimumLogLevel.hashValue >= LogLevel.Debug.hashValue {
        logger?.log(message, level: .Debug)
    }
}

/**
    Logs a warning message on console.

    - parameter message: The warning message to be logged.
*/
public func warning(message: String) {
    if minimumLogLevel.hashValue >= LogLevel.Warning.hashValue {
        logger?.log(message, level: .Warning)
    }
}

/**
    Logs an error message on console.

    - parameter message: The error message to be logged.
*/
public func error(message: String) {
    if minimumLogLevel.hashValue >= LogLevel.Error.hashValue {
        logger?.log(message, level: .Error)
    }
}

/**
    Logs a failure message on console.

    - parameter message: The severe error message to be logged.
*/
public func severe(message: String) {
    if minimumLogLevel.hashValue >= LogLevel.Failure.hashValue {
        logger?.log(message, level: .Failure)
    }
}

// MARK: - TickerLogger

private class TickerLogger {

    private var style: LogLevelStyle

    private var showTimestamp: Bool

    private lazy var dateFormatter: NSDateFormatter = {
        let formatter = NSDateFormatter()
        formatter.locale = NSLocale.currentLocale()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS"

        return formatter
    }()

    init(levelStyle: LogLevelStyle, showTimestamp: Bool) {
        self.style = levelStyle
        self.showTimestamp = showTimestamp
    }

    private func log(message: String, level: LogLevel) {
        let date = showTimestamp ? "\(dateFormatter.stringFromDate(NSDate())) - " : ""

        print("\(date)\(style.description(level))\(message)")
    }

}

// MARK: - LogLevelStyle

public enum LogLevelStyle {

    case Hidden
    case Verbose
    case Symbolic
    case Funny
    case Casual(Bool)

    private func description(level: LogLevel) -> String {
        switch self {
        case .Hidden:
            return ""

        case .Verbose:
            return level.verboseDescription() + ": "

        case .Symbolic:
            return level.symbolicDescription() + " "

        case .Funny:
            return level.funnyDescription() + " "

        case .Casual(let urban):
            return level.casualDescription(urban) + " "
        }
    }

}

// MARK: - LogLevel

public enum LogLevel {

    case Info
    case Debug
    case Warning
    case Error
    case Failure

    private func verboseDescription() -> String {
        switch self {
        case .Info:
            return "Info"

        case .Debug:
            return "Debug"

        case .Warning:
            return "Warning"

        case .Error:
            return "Error"

        case .Failure:
            return "Failure"
        }
    }

    private func symbolicDescription() -> String {
        switch self {
        case .Info:
            return "[NFO]"

        case .Debug:
            return "[DBG]"

        case .Warning:
            return "[WRN]"

        case .Error:
            return "[ERR]"

        case .Failure:
            return "[FLR]"
        }
    }

    private func funnyDescription() -> String {
        switch self {
        case .Info:
            return "📢"

        case .Debug:
            return "🐞"

        case .Warning:
            return "⚠️"

        case .Error:
            return "💩"

        case .Failure:
            return "💣"
        }
    }

    private func casualDescription(urban: Bool) -> String {
        switch self {
        case .Info:
            return "Psst!"

        case .Debug:
            return "Look!"

        case .Warning:
            return "Wait!"

        case .Error:
            return urban ? "S**t!" : "Oops!"

        case .Failure:
            return urban ? "F**k!" : "Ouch!"
        }
    }

}
