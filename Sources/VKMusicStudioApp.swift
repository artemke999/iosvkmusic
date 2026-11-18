import SwiftUI

@main
struct VKMusicStudioApp: App {
    @StateObject private var vkClient = VKAPIClient()
    @StateObject private var player = AudioPlayerManager()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(vkClient)
                .environmentObject(player)
                .onAppear {
                    player.configure(vkClient: vkClient)
                    if vkClient.hasSavedSession {
                        vkClient.bootstrapSession()
                    }
                }
        }
    }
}
