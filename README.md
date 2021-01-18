# PoC of GRPC client in Swift

Works with a serverside written in C# (not available in this repository - commit `e5b3d7e123fbca2f1ada742be278a37af1641d41`).

To generate Swift files from proto files run:
```
protoc SwiftGRPC/proto/* --swift_out=Visibility=Public:. --grpc-swift_out=Visibility=Public,Client=true,Server=false:.
```
