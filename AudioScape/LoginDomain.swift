//
//  LoginFeature.swift
//  AudioScape
//
//  Created by Namashi Sivaram on 2023-10-03.
//

import SwiftUI
import FirebaseFunctions
import Foundation
import ComposableArchitecture


struct LoginDomain: Reducer {
    struct State : Equatable {
        var loggedIn = false
        var loggingIn = false
      }

    enum Action : Equatable {
        case loginButtonTapped
        case incrementButtonTapped
      }

    func reduce(into state: inout State, action: Action) -> Effect<Action> {
        switch action {
        case .loginButtonTapped:
          state.loggingIn = true
          return .none

        case .incrementButtonTapped:
          state.loggedIn = true
          return .none
        }
      }
}

struct LoginFeatureView: View {
  //let store: StoreOf<LoginFeature>

  var body: some View {
    VStack {
      Text("0")
        .font(.largeTitle)
        .padding()
        .background(Color.black.opacity(0.1))
        .cornerRadius(10)
      HStack {
        Button("-") {
        }
        .font(.largeTitle)
        .padding()
        .background(Color.black.opacity(0.1))
        .cornerRadius(10)

        Button("+") {
        }
        .font(.largeTitle)
        .padding()
        .background(Color.black.opacity(0.1))
        .cornerRadius(10)
      }
    }
  }
}

