//
//  AcknowledgementsView.swift
//  ChessOpeningTrainer
//
//  Created by Christian Gleißner on 25.04.23.
//

import SwiftUI

/// One paragraph of license text, or a numbered clause list (e.g. BSD-style "1. / 2. / 3.").
private enum LicenseBodyElement {
    case text(String)
    case numberedList([String])
}

private struct Acknowledgement: Identifiable {
    let id = UUID()
    let title: LocalizedStringResource
    /// Shown under the title in the list row.
    let rowSubtitle: LocalizedStringResource
    let navigationTitle: LocalizedStringResource
    /// Non-footnote header lines shown above the license body (license name, copyright, links).
    var headerLines: [LocalizedStringResource] = []
    let body: [LicenseBodyElement]
}

private let mitPermissionText = "Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the \"Software\"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:"
private let mitNoticeText = "The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software."
private let mitWarrantyText = "THE SOFTWARE IS PROVIDED \"AS IS\", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE."

private let acknowledgements: [Acknowledgement] = [
    Acknowledgement(
        title: "Stockfish",
        rowSubtitle: "GNU General Public License version 3 (GPL v3), https://github.com/official-stockfish/Stockfish",
        navigationTitle: "Stockfish",
        body: [.text(gnuLicence)]
    ),
    Acknowledgement(
        title: "Leela Chess Zero (LC0)",
        rowSubtitle: "GNU General Public License version 3 (GPL v3), https://github.com/LeelaChessZero/lc0",
        navigationTitle: "Leela Chess Zero (LC0)",
        body: [.text(gnuLicence)]
    ),
    Acknowledgement(
        title: "ChessKit Engine",
        rowSubtitle: "MIT License\nCopyright © 2023 ChessKit, <https://github.com/chesskit-app>",
        navigationTitle: "ChessKit Engine",
        headerLines: ["MIT License\nCopyright © 2023 ChessKit\n<https://github.com/chesskit-app>"],
        body: [.text(mitPermissionText), .text(mitNoticeText), .text(mitWarrantyText)]
    ),
    Acknowledgement(
        title: "SVG Files of Chess Pieces",
        rowSubtitle: "CC BY-SA 3.0\nCopyright © Cburnett\nhttps://commons.wikimedia.org/wiki/Category:SVG_chess_pieces",
        navigationTitle: "SVG Files of Chess Pieces",
        headerLines: [
            "CC BY-SA 3.0\n<http://creativecommons.org/licenses/by-sa/3.0/>\nCopyright © Cburnett, via Wikimedia Commons\nhttps://commons.wikimedia.org/wiki/Template:SVG_chess_pieces",
            "The files have not been modified.",
        ],
        body: [
            .text("Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:"),
            .numberedList([
                "Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.",
                "Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.",
                "Neither the name of The author nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.",
            ]),
            .text("THIS SOFTWARE IS PROVIDED BY THE AUTHOR AND CONTRIBUTORS \"AS IS\" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE AUTHOR AND CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE."),
        ]
    ),
    Acknowledgement(
        title: "ChessKit",
        rowSubtitle: "MIT License\nCopyright © 2020 Alexander Perechnev\nhttps://github.com/aperechnev/ChessKit",
        navigationTitle: "ChessKit",
        headerLines: ["MIT License\nCopyright © 2020 Alexander Perechnev\nhttps://github.com/aperechnev/ChessKit"],
        body: [.text(mitPermissionText), .text(mitNoticeText), .text(mitWarrantyText)]
    ),
]

private struct LicenseDetailView: View {
    let acknowledgement: Acknowledgement

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 10) {
                ForEach(Array(acknowledgement.headerLines.enumerated()), id: \.offset) { _, line in
                    Text(line)
                }
                Group {
                    ForEach(Array(acknowledgement.body.enumerated()), id: \.offset) { _, element in
                        switch element {
                        case .text(let text):
                            Text(text)
                        case .numberedList(let items):
                            VStack(alignment: .leading, spacing: 5) {
                                ForEach(Array(items.enumerated()), id: \.offset) { index, item in
                                    HStack(alignment: .top) {
                                        Text("\(index + 1).")
                                            .frame(width: 20, alignment: .leading)
                                        Text(item)
                                    }
                                }
                            }
                        }
                    }
                }
                .font(.footnote)
            }
            .padding()
        }
        .navigationTitle(acknowledgement.navigationTitle)
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct AcknowledgementsView: View {
    var body: some View {
        List {
            ForEach(acknowledgements) { acknowledgement in
                NavigationLink {
                    LicenseDetailView(acknowledgement: acknowledgement)
                } label: {
                    VStack(alignment: .leading) {
                        Text(acknowledgement.title)
                            .font(.system(size: 22))
                            .fontWeight(.bold)
                        Text(acknowledgement.rowSubtitle)
                            .font(.system(size: 16))
                    }
                }
            }
        }
        .navigationTitle("Acknowledgements")
        .navigationBarTitleDisplayMode(.inline)
    }
}
#Preview {
    NavigationStack {
        AcknowledgementsView()
    }
}
