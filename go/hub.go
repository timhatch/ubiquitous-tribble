package main

import (
  "log"

  "github.com/gofiber/websocket/v2"
)

type client struct{} // Add more data to this type if needed

// NOTE: although large maps with pointer-like types (e.g. strings) as keys are slow, using pointers themselves as keys is acceptable and fast
var clients = make(map[*websocket.Conn]client)

func runHub() {
  for {
    select {
    // Add the client to the hub
    case connection := <-register:
      clients[connection] = client{}
      log.Println("connection registered")

    // Broadcast to all clients?
    case message := <-broadcast:
      log.Println("message received:", message)

      for connection := range clients {
        // Try writing to a connection, if the write errors then close the connection and delete it from the clients channel
        // err := connection.WriteMessage(websocket.TextMessage, []byte(message))
        // if err != nil {
        if err := connection.WriteMessage(websocket.TextMessage, []byte(message)); err != nil {
          log.Println("write error:", err)

          connection.WriteMessage(websocket.CloseMessage, []byte{})
          connection.Close()
          delete(clients, connection)
        }
      }

    // Remove the client from the hub
    case connection := <-unregister:
      delete(clients, connection)
      log.Println("connection unregistered")
    }
  }
}

