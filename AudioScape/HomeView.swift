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
        var hub = HubDomain.State(userInfo: nil)
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
        case hubAction(HubDomain.Action)
    }
    struct HomeEnvironment {
      var fetchNumber: @Sendable () async throws -> Int
    }
    var body: some ReducerOf<Self> {
        Scope(state: \.hub, action: /Action.hubAction) {
            HubDomain()
            }
        
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
                                var songs : [String]? = data["songs"] as! [String]?
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
                state.hub.userInfo = userInfo
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
                    if(user.songs.count>0){
                        let randomValue = Int(arc4random_uniform(UInt32(user.songs.count)))
                        userSongs.append(UserSong(uid: user.userID, songid: user.songs[randomValue]))
                    }
                }
                state.userSongList = userSongs
                return .none
            case .logOut:
                return .none
                
            case .logOutSuccess:
                return .none
            case .hubAction(let action):
                if(action == HubDomain.Action.loadUser){
                    print("GABASKI")
                    return .run{send in
                        await send(.loadUser)
                    }
                }
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
                        
                        HubView(
                            store: self.store.scope(
                                state: \.hub,
                                action: HomeDomain.Action.hubAction
                            )
                        )
                           /* HubView(store: Store(initialState: HubDomain.State(userInfo: viewStore.userInfo)){
                                HubDomain()
                                }
                            )*/
                        
                    }.tabItem(){
                        Text("PROFILE")
                    }
                    
                }
            }
            .padding(.leading, 10)
            .padding(.trailing, 10)
            .onReceive(NotificationCenter.default.publisher(for: .AuthSuccess))  { _ in
                        // This code will execute every time the app becomes active
                        // You can put your logic here
                viewStore.send(.loadUser)
                viewStore.send(.startLocationUpdate)
            }
            .onReceive(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)) { _ in
                        // This code will execute every time the app becomes active
                        // You can put your logic here
                viewStore.send(.loadUser)
                viewStore.send(.startLocationUpdate)
            }
            .onAppear{
                viewStore.send(.loadUser)
                viewStore.send(.startLocationUpdate)
            }
            
        }
    }
}
struct HubDomain : Reducer {
    struct State : Equatable{
        var userInfo : UserInfo?
    }
    enum Action : Equatable{
        case loadUser
    }
    func reduce(into state: inout State, action: Action) -> Effect<Action> {
        switch action{
        case .loadUser:
            return .none
        }
    }
}

struct HubView: View {
    let store : StoreOf<HubDomain>
    init(store: StoreOf<HubDomain>) {
        self.store = store
        //self.store.send(.loadUser)
    }
    var body: some View {
        WithViewStore(self.store, observe: { $0 }) { viewStore in
            ZStack {
                if(viewStore.userInfo ==  nil){
                    ProgressView("Loading your profile...")
                        .onAppear(){
                            viewStore.send(.loadUser)
                        }
                }
                else{
                    VStack {
                        HStack{
                            Text("AudioScape")
                                .fontWeight(.heavy)
                                .foregroundColor(.green)
                            
                            Spacer()
                        }
                        HStack{
                            VStack{
                                if (viewStore.userInfo?.profilePics==nil){
                                    Circle()
                                }
                                else{
                                    AsyncImage(url: URL(string: (viewStore.userInfo?.profilePics!.url)!))
                                        .clipShape(Circle())
                                }
                                // Adjust the size as needed
                                // Optionally make the image circular
                                Text("\(viewStore.userInfo!.dispName)")
                                ForEach(viewStore.userInfo!.songs!, id: \.self) { userSong in
                                    UserSongView(
                                        store: Store(
                                            initialState: UserSongDomain.State(userSong: UserSong(uid: viewStore.userInfo!.userID, songid: userSong))
                                        ) {
                                            UserSongDomain()
                                        }
                                    )
                                }
                            }
                            Spacer()
                        }
                        
                        Spacer()
                    }
                
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
   
