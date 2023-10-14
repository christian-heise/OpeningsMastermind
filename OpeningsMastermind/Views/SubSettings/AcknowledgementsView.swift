//
//  AcknowledgementsView.swift
//  ChessOpeningTrainer
//
//  Created by Christian Gleißner on 25.04.23.
//

import SwiftUI

struct AcknowledgementsView: View {
    var body: some View {
        NavigationStack {
            List {
                NavigationLink {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 10) {
                            Group {
                                Text(gnuLicence)
                            }
                            .font(.footnote)
                        }
                        .padding()
                    }
                    .navigationTitle("Stockfish")
                } label: {
                    VStack(alignment: .leading) {
                        Text("Stockfish")
                            .font(.system(size: 22))
                            .fontWeight(.bold)
                        Text("GNU General Public License version 3 (GPL v3), https://github.com/official-stockfish/Stockfish")
                            .font(.system(size: 16))
                    }
                }
                NavigationLink {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 10) {
                            Group {
                                Text(gnuLicence)
                            }
                            .font(.footnote)
                        }
                        .padding()
                    }
                    .navigationTitle("Leela Chess Zero (LC0)")
                } label: {
                    VStack(alignment: .leading) {
                        Text("Leela Chess Zero (LC0)")
                            .font(.system(size: 22))
                            .fontWeight(.bold)
                        Text("GNU General Public License version 3 (GPL v3), https://github.com/LeelaChessZero/lc0")
                            .font(.system(size: 16))
                    }
                }
                NavigationLink {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("MIT License\nCopyright © 2023 ChessKit\n<https://github.com/chesskit-app>")
                            Group {
                                Text("Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the \"Software\"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:")
                                
                                Text("The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.")
                                
                                Text("THE SOFTWARE IS PROVIDED \"AS IS\", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.")
                            }
                            .font(.footnote)
                        }
                        .padding()
                    }
                    .navigationTitle("ChessKit Engine")
                } label: {
                    VStack(alignment: .leading) {
                        Text("ChessKit Engine")
                            .font(.system(size: 22))
                            .fontWeight(.bold)
                        Text("MIT License\nCopyright © 2023 ChessKit, <https://github.com/chesskit-app>")
                            .font(.system(size: 16))
                    }
                }
                NavigationLink {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("CC BY-SA 3.0\n<http://creativecommons.org/licenses/by-sa/3.0/>\nCopyright © Cburnett, via Wikimedia Commons\nhttps://commons.wikimedia.org/wiki/Template:SVG_chess_pieces")
                            Text("The files have not been modified.")

                            Group {
                                Text("Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:")

                                VStack(alignment: .leading, spacing: 5) {
                                    HStack(alignment: .top) {
                                        Text("1.")
                                            .frame(width: 20,alignment: .leading)
                                        Text("Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.")
                                    }
                                    HStack(alignment: .top){
                                        Text("2.")
                                            .frame(width: 20,alignment: .leading)
                                        Text("Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.")
                                    }
                                    HStack(alignment: .top){
                                        Text("3.")
                                            .frame(width: 20,alignment: .leading)
                                        Text("Neither the name of The author nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.")
                                    }
                                }

                                Text("THIS SOFTWARE IS PROVIDED BY THE AUTHOR AND CONTRIBUTORS \"AS IS\" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE AUTHOR AND CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.")
                            }
                            .font(.footnote)
                        }

                        .padding()
                    }
                    .navigationTitle("SVG Files of Chess Pieces")
                    .navigationBarTitleDisplayMode(.inline)
                } label: {
                    VStack(alignment: .leading) {
                        Text("SVG Files of Chess Pieces")
                            .font(.system(size: 22))
                            .fontWeight(.bold)
                        Text("CC BY-SA 3.0\nCopyright © Cburnett\nhttps://commons.wikimedia.org/wiki/Category:SVG_chess_pieces")
                            .font(.system(size: 16))
                    }
                }
                NavigationLink {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("MIT License\nCopyright © 2020 Alexander Perechnev\nhttps://github.com/aperechnev/ChessKit")

                            Group {
                                Text("Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the \"Software\"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:")

                                Text("The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.")

                                Text("THE SOFTWARE IS PROVIDED \"AS IS\", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.")
                            }
                            .font(.footnote)
                        }
                        .padding()
                    }
                    .navigationTitle("ChessKit")
                    .navigationBarTitleDisplayMode(.inline)
                } label: {
                    VStack(alignment: .leading) {
                        Text("ChessKit")
                            .font(.system(size: 22))
                            .fontWeight(.bold)
                        Text("MIT License\nCopyright © 2020 Alexander Perechnev\nhttps://github.com/aperechnev/ChessKit")
                            .font(.system(size: 16))
                    }
                }
            }
            .navigationTitle("Acknowledgements")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

struct AcknowledgementsView_Previews: PreviewProvider {
    static var previews: some View {
        AcknowledgementsView()
    }
}
