import SwiftUI

struct StaffTabView: View {
    let uid: String
    @Environment(AuthManager.self) private var authManager
    @State private var staffVM: StaffViewModel
    @State private var availabilityVM: AvailabilityViewModel
    @State private var bookingVM: BookingViewModel

    init(uid: String, firestoreService: FirestoreService, storageService: StorageService) {
        self.uid = uid
        _staffVM = State(initialValue: StaffViewModel(firestoreService: firestoreService, storageService: storageService))
        _availabilityVM = State(initialValue: AvailabilityViewModel(firestoreService: firestoreService))
        _bookingVM = State(initialValue: BookingViewModel(firestoreService: firestoreService))
    }

    var body: some View {
        TabView {
            Tab("Shows", systemImage: "calendar.badge.clock") {
                ShowsListView(uid: uid, viewModel: availabilityVM, bookingVM: bookingVM, staffVM: staffVM)
            }

            Tab("Bookings", systemImage: "list.clipboard") {
                StaffBookingsView(uid: uid, viewModel: bookingVM, showMap: bookingVM.showMap)
            }

            Tab("Profile", systemImage: "person.crop.circle") {
                StaffProfileView(uid: uid, viewModel: staffVM)
            }
        }
        .tint(.brand)
        .task {
            await staffVM.loadStaff(uid: uid)
            await availabilityVM.loadShows(staffId: uid, staffLocation: staffVM.staff?.location)
            await bookingVM.loadStaffBookings(staffId: uid)
        }
    }
}
