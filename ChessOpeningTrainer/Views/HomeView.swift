////
////  HomeView.swift
////  ChessOpeningTrainer
////
////  Created by Christian Gleißner on 18.05.23.
////
//
//import SwiftUI
//
//struct HomeView: View {
//    @StateObject var settings = Settings()
//    @StateObject var database = DataBase()
//    
//    var body: some View {
//        NavigationStack {
//            VStack {
//                HStack {
//                    NavigationLink(destination: PracticeView(database: database, settings: settings)) {
//                        ZStack {
//                            RoundedRectangle(cornerRadius: 20)
//                                .fill([222, 155, 160].getColor())
//                            VStack {
//                                Image(systemName: "checkerboard.rectangle")
//                                    .resizable()
//                                    .scaledToFit()
//                                    .padding(30)
//                                Text("Practice")
//                                    .font(.title)
//                            }
//                            .foregroundColor([34, 34, 34].getColor())
//                        }
//                    }
//                    NavigationLink(destination: ExploreView(database: database, settings: settings)) {
//                        ZStack {
//                            RoundedRectangle(cornerRadius: 20)
//                                .fill([242, 161, 119].getColor())
//                            VStack {
//                                Image(systemName: "safari")
//                                    .resizable()
//                                    .scaledToFit()
//                                    .padding(30)
//                                Text("Explorer")
//                                    .font(.title)
//                            }
//                            .foregroundColor([34, 34, 34].getColor())
//                        }
//                    }
//                }
//                HStack {
//                    NavigationLink(destination: ListView(database: database)) {
//                        ZStack {
//                            RoundedRectangle(cornerRadius: 20)
//                                .fill([110, 159, 82].getColor())
//                                .shadow(radius: 2)
//                            VStack {
//                                Image(systemName: "list.bullet")
//                                    .resizable()
//                                    .scaledToFit()
//                                    .padding(30)
//                                Text("Library")
//                                    .font(.title)
//                            }
//                            .foregroundColor([34, 34, 34].getColor())
//                        }
//                    }
//                    NavigationLink(destination: SettingsView(settings: settings)) {
//                        ZStack {
//                            RoundedRectangle(cornerRadius: 20)
//                                .fill([232, 229, 114].getColor())
//                            VStack {
//                                Image(systemName: "gear")
//                                    .resizable()
//                                    .scaledToFit()
//                                    .padding(30)
//                                Text("Settings")
//                                    .font(.title)
//                            }
//                            .foregroundColor([34, 34, 34].getColor())
//                        }
//                    }
//                    
//                }
//            }
//            .padding()
//            .navigationTitle("Openings Mastermind")
//        }
//    }
//}
//
//
//struct HomeView_Previews: PreviewProvider {
//    static var previews: some View {
//        HomeView()
//    }
//}
