//
//  SystemEnvironment.swift
//  AudioScape
//
//  Created by Namashi Sivaram on 2023-10-18.
//

import Foundation
import ComposableArchitecture
@dynamicMemberLookup
struct SystemEnvironment<Environment> {
  var environment: Environment
  var mainQueue: AnySchedulerOf<DispatchQueue>


  subscript<Dependency>(
    dynamicMember keyPath: WritableKeyPath<Environment, Dependency>
  ) -> Dependency {
    get { self.environment[keyPath: keyPath] }
    set { self.environment[keyPath: keyPath] = newValue }
  }

  /// Creates a live system environment with the wrapped environment provided.
  ///
  /// - Parameter environment: An environment to be wrapped in the system environment.
  /// - Returns: A new system environment.
  static func live(environment: Environment) -> Self {
    Self(
      environment: environment,
      mainQueue: .main
    )
  }

  /// Transforms the underlying wrapped environment.
  func map<NewEnvironment>(
    _ transform: @escaping (Environment) -> NewEnvironment
  ) -> SystemEnvironment<NewEnvironment> {
    .init(
      environment: transform(self.environment),
      mainQueue: self.mainQueue
      
    )
  }
}

extension SystemEnvironment: Sendable where Environment: Sendable {}
