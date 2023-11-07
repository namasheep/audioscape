import SwiftUI
import CoreLocation
import FirebaseAuth
import FirebaseFunctions
import ComposableArchitecture



struct HomeDomain : Reducer{
    
    var locationManager: LocationManager
    struct State : Equatable{
        var loadingUser = true
        var userInfo : UserInfo?
        var userList : [User]?
        var userSongList : [UserSong]?
        
    }
    enum Action : Equatable {
        case loadUser
        case loadUserSuccess(UserInfo?)
        case loadUserError
        case test
        case startLocationUpdate
        case getUsersWithLocation
        case getUsersWithLocationSuccess([User])
        case logOut
        case logOutSuccess
    }
    struct HomeEnvironment {
      var fetchNumber: @Sendable () async throws -> Int
    }
    var body: some ReducerOf<Self> {
        
        
        Reduce { state, action in
            switch action{
            case .startLocationUpdate:
                // Request location permission
                locationManager.requestLocation()
                print("STRAVZ")
                return .none
            case .loadUser:
                state.loadingUser = true
                return .run{
                    send in
                    Task.init{
                        do{
                            let result = try await Functions.functions().httpsCallable("getUserInfo").call(["uid": Auth.auth().currentUser?.uid])
                            var userInfo : UserInfo?
                            if let data = result.data as? [String: Any]{
                                let uid : String  = data["uid"] as! String
                                let href : String = data["href"] as! String
                                
                                var img : ProfilePicture?
                                if let imgData = data["images"] as? [String: Any]{
                                    img = ProfilePicture(height: imgData["height"] as! Int ,width: imgData["height"] as! Int, url: imgData["url"] as! String)
                                }
                                let disp = data["display_name"] as! String
                                var songs : [String]?
                                userInfo = UserInfo(userID: uid, songs: songs, href: href, dispName: disp, img: img)
                            }
                            await send(.loadUserSuccess(userInfo))
                            return
                        }
                        catch{
                           await send(.loadUserError)
                        }
                        
                    }
                }
                
            case .loadUserSuccess(let userInfo):
                state.loadingUser = false
                
                state.userInfo = userInfo
                return .none
                
            case .loadUserError:
                return .none
                
            case .test:
                state.loadingUser = false
                return .none
            case .getUsersWithLocation:
                if(!locationManager.checkLocationServicesEnabled()){
                    print("No location gotten")
                    return .none
                }
                else{
                    return .run{ send in
                        Task {
                            do {
                                guard let geo = locationManager.getLocationHash() else{
                                    return
                                }
                                print(geo)
                                let result = try await Functions.functions().httpsCallable("getUsersWithSameLocation").call(["location": geo])
                                if let data = result.data as? [String: Any], let usersList = data["users_list"] as? [[String: Any]] {
                                    var users: [User] = []

                                    for userDictionary in usersList {
                                        if let uid = userDictionary["uid"] as? String, let songs = userDictionary["songs"] as? [String] {
                                            let user = User(userID: uid, songs: songs)
                                            if(user.userID != Auth.auth().currentUser?.uid){
                                                users.append(user)
                                            }
                                        }
                                    }
                                    await send(.getUsersWithLocationSuccess(users))
                                  }
                                /*
                                 if let data = result.data as? [String: Any],
                                 let customToken = data["fire_token"] as? String,
                                 let accessToken = data["access_token"] as? String,
                                 let uid = data["id"] as? String {
                                 do {
                                 let authResult = try await Auth.auth().signIn(withCustomToken: customToken)
                                 
                                 print("User signed in: \(authResult.user.uid ?? "")")
                                 await send(.signInSuccess)
                                 // You can perform any further actions after the user is signed in
                                 
                                 }
                                 catch{
                                 print("ERROR in FIREBASE")
                                 }
                                 }*/
                            } catch {
                                print("Error during getting users: \(error)")
                            }
                        }
                    }
                }
            case .getUsersWithLocationSuccess(let userList):
                var userSongs : [UserSong] = []
                state.userList = userList
                for user in userList {
                    // Your code for each user goes here
                    let randomValue = Int(arc4random_uniform(3))
                    userSongs.append(UserSong(uid: user.userID, songid: user.songs[randomValue]))
                }
                state.userSongList = userSongs
                return .none
            case .logOut:
                return .none
                
            case .logOutSuccess:
                return .none
            }
        }
    }
    
}
struct HomeView: View {
    
    let store: StoreOf<HomeDomain>
    init(store: StoreOf<HomeDomain>) {
        self.store = store
        
    }
    var body: some View {
        WithViewStore(self.store, observe: { $0 }) { viewStore in
            VStack{
                TabView{
                    Section{
                        VStack{
                            if(viewStore.userSongList != nil){
                                ForEach(viewStore.userSongList!, id: \.self) { userSong in
                                    UserSongView(
                                        store: Store(
                                            initialState: UserSongDomain.State(userSong: userSong)
                                        ) {
                                            UserSongDomain()
                                        }
                                    )
                                }
                            }
                            Button("Create AudioScape"){
                                print(viewStore.userInfo,"SDDSDSDS")
                                viewStore.send(.getUsersWithLocation)
                            }
                            Button("Logout"){
                                print("GREESH")
                                viewStore.send(.logOut)
                            }
                            
                        }
                        
                        
                    }.tabItem(){
                        Text("HOME")
                    }
                    Section{
                        if(viewStore.loadingUser ==  true){
                            ProgressView("Loading your profile...")
                        }
                        else{
                            HubView(store: Store(initialState: HubDomain.State(userInfo: viewStore.userInfo!)){
                                HubDomain()
                                }
                            )
                        }
                    }.tabItem(){
                        Text("PROFILE")
                    }
                    
                }
            }
            .padding(.leading, 10)
            .padding(.trailing, 10)
            .onAppear{
                viewStore.send(.loadUser)
                viewStore.send(.startLocationUpdate)
            }
            
        }
    }
}
struct HubDomain : Reducer {
    struct State : Equatable{
        var userInfo : UserInfo
    }
    enum Action : Equatable{
        
    }
    func reduce(into state: inout State, action: Action) -> Effect<Action> {
        
    }
}

struct HubView: View {
    let store : StoreOf<HubDomain>
    var body: some View {
        WithViewStore(self.store, observe: { $0 }) { viewStore in
            ZStack {
                                
                VStack {
                    HStack{
                        Text("AudioScape")
                            .fontWeight(.heavy)
                            .foregroundColor(.green)
                            
                        Spacer()
                    }
                    HStack{
                        VStack{
                            AsyncImage(url: URL(string: (viewStore.userInfo.profilePics!.url)))
                            // Adjust the size as needed
                                .clipShape(Circle()) // Optionally make the image circular
                            Text("\(viewStore.userInfo.dispName)")
                        }
                        Spacer()
                    }
                    
                    Spacer()
                }
                
            }
            
        }
    }
}
        /*
        GeometryReader { geometry in
            ZStack{
                Color(red: 0.187, green: 0.233, blue: 0.392)
                    .edgesIgnoringSafeArea(.all)
                VStack{
                    HStack(alignment: .top){
                        Image(systemName: "person.crop.circle")
                            .renderingMode(.original)
                            .resizable()
                            .frame(width: 120,height: 120,alignment: .leading)
                        Spacer()
                        VStack{
                            Text(authManager.userInfo?.dispName ?? "WHO")
                                .font(.system(size: 20,weight: .heavy))
                                .foregroundColor(.white)
                                .frame(alignment: .top)
                        }
                        Spacer()
                    }
                    .padding(.horizontal, 26.0)
                    Spacer()
                    Button("Log Out", action: logoutAction)
                        .padding()

                }
            }
        }
            
            
        VStack {
            if showUserList {
                List(userList, id: \.uid) { user in
                    Text("\(user.uid) \(user.songid)") // Replace with your user data display
                }
                .padding()
            } else {
                Button(action: {
                    HomeModel.getUsersWithGeohash(targetGeohash: locationManager.getLocationHash()!) { users in
                        // Handle the users array here
                        userList = users ?? []
                        print(userList)
                        showUserList = !userList.isEmpty
                        // Show the list if not empty
                    }
                }) {
                    Text("AudioScape")
                        .font(.title)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .foregroundColor(.white)
                }
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(LinearGradient(gradient: Gradient(colors: [Color.green.opacity(0.8), Color.green.opacity(0.6)]), startPoint: .topLeading, endPoint: .bottomTrailing))
                )
                .padding(.horizontal, 20)
            }
            
            Spacer()
            
            Button("Log Out", action: logoutAction)
                .padding()
        }
        .onAppear {
            // Call the checkAndRequestLocationAccess() function when HomeView appears
            //checkAndRequestLocationAccess()
        }
    }
}
         */

struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        
            HomeView(
                store: Store(initialState: HomeDomain.State()) {
                    HomeDomain(locationManager: AppEnvironment.locationManager)
                }
            )
    }
}
   
