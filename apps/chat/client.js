const url = "ws://localhost:3000/chat"
const socket = new WebSocket(url)

socket.addEventListener('message', (event) => {
    var data = JSON.parse(event.data)
    console.log('Message', data)
})

socket.addEventListener('open', () => {
    console.log('Connection open')
    socket.send(new Date().toString())
})
