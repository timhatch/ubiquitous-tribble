package main

import (
  "log"

  "github.com/gofiber/fiber/v2"
  "github.com/gofiber/websocket/v2"
)

var register   = make(chan *websocket.Conn)
var broadcast  = make(chan string)
var unregister = make(chan *websocket.Conn)

func main() {
  app := fiber.New()

  app.Static("/", "./home.html")

  app.Use(func(c *fiber.Ctx) error {
    if websocket.IsWebSocketUpgrade(c) { // Returns true if the client requested upgrade to the WebSocket protocol
      return c.Next()
    }
    return c.SendStatus(fiber.StatusUpgradeRequired)
  })

  go runHub()

  app.Get("/ws", websocket.New(func(c *websocket.Conn) {
    // When the function returns, unregister the client and close the connection
    defer func() {
      unregister <- c
      c.Close()
    }()

    // Register the client
    register <- c

    // Loop and execute a handler
    for {
      messageType, message, err := c.ReadMessage()

      if err != nil {
        if websocket.IsUnexpectedCloseError(err, websocket.CloseGoingAway, websocket.CloseAbnormalClosure) {
          log.Println("read error:", err)
        }

        return // Calls the deferred function, i.e. closes the connection on error
      }

      if messageType == websocket.TextMessage {
        broadcast <- string(message) // Send the received message to the `broadcast` channel
      } else {
        log.Println("websocket message received of type", messageType)
      }
    }
  }))

  log.Fatal(app.Listen(":3000"))
}
