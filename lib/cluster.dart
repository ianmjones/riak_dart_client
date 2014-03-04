part of riak_client;

/** A Riak endpoint */
class Node {

  final String host;
  final int httpPort;
  final int pbPort;

  Endpoint _httpEndpoint;
  Endpoint _pbEndpoint;

  Node(this.host, {this.httpPort: 8098, this.pbPort: 8087}) {
    _httpEndpoint = new Endpoint(host, httpPort);
    _pbEndpoint = new Endpoint(host, pbPort);
  }

  bool operator ==(Node other) =>
      host == other.host &&
      httpPort == other.httpPort &&
      pbPort == other.pbPort;

  int get hashCode =>
      host.hashCode + httpPort * 13 + pbPort * 11;
}

/** A Riak cluster with multiple [Node]s. */
class _Cluster {

  final String name;
  List<Node> _nodes = [];
  ConnectionPool<HttpClient> _httpPool;
  ConnectionPool<Socket> _pbPool;

  _Cluster(this.name) {
    _httpPool = new ConnectionPool.http("$name/http");
    _pbPool = new ConnectionPool.socket("$name/pb");
  }

  void join(Node node) {
    if (_nodes.contains(node)) {
      return;
    }
    _httpPool.join(node._httpEndpoint);
    _pbPool.join(node._pbEndpoint);
    _nodes.add(node);
  }

  void leave(Node node) {
    if (!_nodes.contains(node)) {
      return;
    }
    _httpPool.leave(node._httpEndpoint);
    _pbPool.leave(node._pbEndpoint);
    _nodes.remove(node);
  }

  Future close() {
    return Future.wait([_httpPool.close(), _pbPool.close()]);
  }
}