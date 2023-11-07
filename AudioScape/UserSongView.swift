//
//  UserSongView.swift
//  AudioScape
//
//  Created by Namashi Sivaram on 2023-10-28.
//

import Foundation
import ComposableArchitecture
import SwiftUI
import FirebaseFunctions
import FirebaseAuth

struct UserSongDomain : Reducer{
    struct State : Equatable{
        var userSong : UserSong
        var song : Song?
        var loaded = false
    }
    enum Action : Equatable{
        case loadSong
        case loadSongSuccess(Song?)
        case loadSongError
    }
    var body: some ReducerOf<Self> {
        
        
        Reduce { state, action in
            switch action{
            case .loadSong:
                return .run{[userSong = state.userSong] send in
                    Task.init{
                        do{
                            let result = try await Functions.functions().httpsCallable("getSong").call(["songID": userSong.songid])
                            var song : Song?
                            if let data = result.data as? [String: Any]{
                                let name : String  = data["name"] as! String
                                let id : String = data["id"] as! String
                                print(data)
                                song = Song(id: id, name: name);
                            }
                            await send(.loadSongSuccess(song))
                            return
                        }
                        catch{
                           await send(.loadSongError)
                        }
                        
                    }
                }
            case .loadSongSuccess(let song):
                state.song = song
                state.loaded = true
                return .none
            case .loadSongError:
                return .none
            }
        }
    }
}
struct UserSongView: View {
    
    
    
    let store: StoreOf<UserSongDomain>
    // Replace with your user identifier
    init(store: StoreOf<UserSongDomain>) {
            self.store = store
            self.store.send(.loadSong)
        }
    
    var body: some View {
        WithViewStore(self.store, observe: { $0 }) { viewStore in
            ZStack{
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color.green, lineWidth: 2)
                    .frame(width: .infinity, height: 80)
                if(viewStore.loaded){
                    HStack{
                        Rectangle()
                            .frame(width: 60,height: 60)
                        VStack{
                            Text(viewStore.song!.name)
                                .font(.headline)
                            Text("artist")
                        }
                        Spacer()
                        Circle()
                            .frame(width: 20,height: 20)
                        
                    }
                    .padding(.leading,10)
                    .padding(.trailing,10)
                    
                }
                else{
                    ProgressView()
                }
            }
            
        }
    }
}

struct UserSongView_Previews: PreviewProvider {
    static var previews: some View {
        UserSongView(
            store: Store(initialState: UserSongDomain.State(userSong: UserSong(uid: "namasheep", songid: "11dFghVXANMlKmJXsNCbNl"))) {
            UserSongDomain()
          }
        )
    }
}
