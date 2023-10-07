import SwiftUI
import FirebaseFunctions
struct LoginView: View {
    var loginAction: () -> Void
    //let store: StoreOf<CounterFeature>
    
    var body: some View {
        EmptyView()
        /*
        VStack {
            Image("your_logo") // Replace with your app logo
                .resizable()
                .frame(width: 100, height: 100)
            
            Text("Welcome to Audio Scape") // Replace with your app name
                .font(.title)
                .padding()
            
            Button(action: loginAction) {
                Text("Login with Spotify")
                    .padding()
                    .foregroundColor(.white)
                    .background(Color.green)
                    .cornerRadius(8)
            }
            Button(action: {
                // Call your Google Cloud Function here
                callGoogleCloudFunction()
            }) {
                Text("Call Cloud Function")
                    .padding()
                    .foregroundColor(.white)
                    .background(Color.blue)
                    .cornerRadius(8)
            }
        }
        .padding()
         */
    }
    func callGoogleCloudFunction(){
        lazy var functions = Functions.functions();
        functions.httpsCallable("helloWorld").call() { result, error in
            if let error = error as NSError? {
                if error.domain == FunctionsErrorDomain {
                    print(error);
                }
                // ...
            }
            if let data = result?.data as? [String: Any], let text = data["text"] as? String {
                print(text);
            }
        }
    }
}
