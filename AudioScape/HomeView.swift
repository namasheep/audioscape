import SwiftUI
import FirebaseAuth

struct HomeView: View {
    var logoutAction: () -> Void
    @EnvironmentObject private var locationManager: LocationManager
    @EnvironmentObject private var authManager: AuthManager
    
    @State private var userList: [UserSong] = []
    @State private var showUserList = false // Flag to control the user list visibility
    
    var body: some View {
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
            
            
        /*VStack {
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
        }*/
    }
}

struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        HomeView(logoutAction: { print("logout") })
    }
}
