//
// DO NOT EDIT.
//
// Generated by the protocol buffer compiler.
// Source: search.proto
//

//
// Copyright 2018, gRPC Authors All rights reserved.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//
import GRPC
import NIO
import SwiftProtobuf


/// Usage: instantiate `Search_SearchServiceClient`, then call methods of this protocol to make API calls.
public protocol Search_SearchServiceClientProtocol: GRPCClient {
  var serviceName: String { get }
  var interceptors: Search_SearchServiceClientInterceptorFactoryProtocol? { get }

  func searchCustomers(
    _ request: Search_SearchCustomersRequest,
    callOptions: CallOptions?
  ) -> UnaryCall<Search_SearchCustomersRequest, Search_SearchCustomersResponse>

  func getCustomerById(
    _ request: Search_GetCustomerByIdRequest,
    callOptions: CallOptions?
  ) -> UnaryCall<Search_GetCustomerByIdRequest, Search_GetCustomerByIdResponse>
}

extension Search_SearchServiceClientProtocol {
  public var serviceName: String {
    return "search.SearchService"
  }

  /// Unary call to SearchCustomers
  ///
  /// - Parameters:
  ///   - request: Request to send to SearchCustomers.
  ///   - callOptions: Call options.
  /// - Returns: A `UnaryCall` with futures for the metadata, status and response.
  public func searchCustomers(
    _ request: Search_SearchCustomersRequest,
    callOptions: CallOptions? = nil
  ) -> UnaryCall<Search_SearchCustomersRequest, Search_SearchCustomersResponse> {
    return self.makeUnaryCall(
      path: "/search.SearchService/SearchCustomers",
      request: request,
      callOptions: callOptions ?? self.defaultCallOptions,
      interceptors: self.interceptors?.makeSearchCustomersInterceptors() ?? []
    )
  }

  /// Unary call to GetCustomerById
  ///
  /// - Parameters:
  ///   - request: Request to send to GetCustomerById.
  ///   - callOptions: Call options.
  /// - Returns: A `UnaryCall` with futures for the metadata, status and response.
  public func getCustomerById(
    _ request: Search_GetCustomerByIdRequest,
    callOptions: CallOptions? = nil
  ) -> UnaryCall<Search_GetCustomerByIdRequest, Search_GetCustomerByIdResponse> {
    return self.makeUnaryCall(
      path: "/search.SearchService/GetCustomerById",
      request: request,
      callOptions: callOptions ?? self.defaultCallOptions,
      interceptors: self.interceptors?.makeGetCustomerByIdInterceptors() ?? []
    )
  }
}

public protocol Search_SearchServiceClientInterceptorFactoryProtocol {

  /// - Returns: Interceptors to use when invoking 'searchCustomers'.
  func makeSearchCustomersInterceptors() -> [ClientInterceptor<Search_SearchCustomersRequest, Search_SearchCustomersResponse>]

  /// - Returns: Interceptors to use when invoking 'getCustomerById'.
  func makeGetCustomerByIdInterceptors() -> [ClientInterceptor<Search_GetCustomerByIdRequest, Search_GetCustomerByIdResponse>]
}

public final class Search_SearchServiceClient: Search_SearchServiceClientProtocol {
  public let channel: GRPCChannel
  public var defaultCallOptions: CallOptions
  public var interceptors: Search_SearchServiceClientInterceptorFactoryProtocol?

  /// Creates a client for the search.SearchService service.
  ///
  /// - Parameters:
  ///   - channel: `GRPCChannel` to the service host.
  ///   - defaultCallOptions: Options to use for each service call if the user doesn't provide them.
  ///   - interceptors: A factory providing interceptors for each RPC.
  public init(
    channel: GRPCChannel,
    defaultCallOptions: CallOptions = CallOptions(),
    interceptors: Search_SearchServiceClientInterceptorFactoryProtocol? = nil
  ) {
    self.channel = channel
    self.defaultCallOptions = defaultCallOptions
    self.interceptors = interceptors
  }
}

