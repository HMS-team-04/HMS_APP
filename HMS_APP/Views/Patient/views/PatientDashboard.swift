//
//  PatientDashboard.swift
//  MediCareManager
//
//  Created by s1834 on 22/04/25.
//

import SwiftUI
import FirebaseFirestore

struct PatientDashboardView: View {
    @EnvironmentObject var appointmentManager: AppointmentManager
    @EnvironmentObject var authManager: AuthManager
    @State private var patient: Patient?
    @State private var isLoading = true
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.accessibilityReduceMotion) var reduceMotion
    @Environment(\.dynamicTypeSize) var dynamicTypeSize

    var currentAppointments: [AppointmentData] {
        appointmentManager.patientAppointments.filter {
            $0.status == .scheduled || $0.status == .inProgress || $0.status == .rescheduled || $0.status == .noShow
        }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                if isLoading {
                    ProgressView("Loading patient dashboard")
                        .progressViewStyle(CircularProgressViewStyle())
                        .scaleEffect(1.5)
                        .padding()
                        .accessibilityLabel("Loading patient dashboard")
                        .accessibilityHint("Please wait while the dashboard loads")
                } else {
                    DashboardHeaderView(patientName: patient?.name ?? "Patient")
                    QuickActionsView()

                    if appointmentManager.isLoading {
                        ProgressView("Loading appointments")
                            .progressViewStyle(CircularProgressViewStyle())
                            .padding()
                            .accessibilityLabel("Loading appointments")
                            .accessibilityHint("Please wait while appointments load")
                    } else if currentAppointments.isEmpty {
                        NoAppointmentsView()
                    } else {
                        CurrentAppointmentsSection(appointments: currentAppointments)
                    }

                    LatestReportsView()
                    RemindersView()
                }
            }
            .padding(.vertical)
            .dynamicTypeSize(...DynamicTypeSize.xxxLarge) // Support dynamic type
        }
        .navigationBarHidden(true)
        .task {
            if reduceMotion {
                await fetchPatientInfo()
                await appointmentManager.fetchAppointments()
            } else {
                withAnimation {
                    Task {
                        await fetchPatientInfo()
                        await appointmentManager.fetchAppointments()
                    }
                }
            }
        }
        .refreshable {
            await fetchPatientInfo()
            await appointmentManager.fetchAppointments()
        }
        .background(colorScheme == .dark ? Theme.dark.background : Theme.light.background)
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Patient Dashboard")
        .accessibilityHint("View your appointments, reports, and reminders")
    }
    
    private func fetchPatientInfo() async {
        guard let userId = UserDefaults.standard.string(forKey: "userId") else {
            isLoading = false
            return
        }
        
        let email = "user@gmail.com"
        do {
            let patientData = try await PatientFirestoreService.shared.getOrCreatePatient(
                userId: userId,
                name: "Patient",
                email: email,
                gender: "Male"
            )
            
            await MainActor.run {
                self.patient = patientData
                self.isLoading = false
            }
        } catch {
            print("Error fetching patient data: \(error.localizedDescription)")
            await MainActor.run {
                self.isLoading = false
            }
        }
    }
}

// MARK: - Dashboard Header
struct DashboardHeaderView: View {
    let patientName: String
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Welcome Back,")
                    .font(.title3)
                    .foregroundColor(.gray)
                    .accessibilityHidden(true) // Decorative text
                Text(patientName)
                    .font(.title)
                    .bold()
                    .foregroundColor(colorScheme == .dark ? .white : .primary)
                    .accessibilityLabel("Patient name: \(patientName)")
            }
            Spacer()
            
            NavigationLink {
                PatientProfileView()
            } label: {
                Image(systemName: "person.crop.circle.fill")
                    .resizable()
                    .frame(width: 40, height: 40)
                    .foregroundColor(colorScheme == .dark ? Theme.dark.primary : .medicareBlue)
                    .padding(5)
                    .background(
                        Circle()
                            .fill(colorScheme == .dark ? Theme.dark.card : .white)
                            .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
                    )
                    .accessibilityLabel("View profile")
                    .accessibilityHint("Tap to view your patient profile")
                    .accessibilityAddTraits(.isButton)
            }
            .buttonStyle(.plain) // Improves keyboard navigation
            .minimumScaleFactor(0.8)
        }
        .padding(.horizontal)
        .accessibilityElement(children: .combine)
    }
}

// MARK: - No Appointments View
struct NoAppointmentsView: View {
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack(spacing: 16) {
            Text("No Upcoming Appointments")
                .font(.headline)
                .foregroundColor(colorScheme == .dark ? .white : .primary)
                .padding(.top)
                .accessibilityLabel("No upcoming appointments available")
            
            Text("Book an appointment with a doctor to get started")
                .font(.subheadline)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
                .accessibilityLabel("Book an appointment to get started")
            
            NavigationLink(destination: DoctorsView()) {
                Text("Find a Doctor")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                    .background(colorScheme == .dark ? Theme.dark.primary : Color.medicareBlue)
                    .cornerRadius(10)
                    .accessibilityLabel("Find a doctor")
                    .accessibilityHint("Tap to search for available doctors")
                    .accessibilityAddTraits(.isButton)
            }
            .buttonStyle(.plain)
            .padding()
            .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity)
        .background(colorScheme == .dark ? Theme.dark.card : Theme.light.card)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
        .padding(.horizontal)
        .accessibilityElement(children: .combine)
    }
}

// MARK: - Quick Actions
struct QuickActionsView: View {
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Quick Actions")
                .font(.headline)
                .foregroundColor(colorScheme == .dark ? .white : .primary)
                .padding(.horizontal)
                .accessibilityLabel("Quick actions section")
            
            HStack(spacing: 15) {
                NavigationLink(destination: DoctorsView()) {
                    DashboardActionButton(title: "Book Appointment", icon: "calendar.badge.plus")
                        .accessibilityLabel("Book appointment")
                        .accessibilityHint("Tap to schedule a new appointment")
                }
                .buttonStyle(.plain)

                NavigationLink(destination: QuestionaireContentView()) {
                    DashboardActionButton(title: "Find Doctor", icon: "stethoscope")
                        .accessibilityLabel("Find doctor")
                        .accessibilityHint("Tap to search for a doctor")
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal)
        }
        .accessibilityElement(children: .combine)
    }
}

struct DashboardActionButton: View {
    let title: String
    let icon: String
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.white)
                .padding()
                .background(colorScheme == .dark ? Theme.dark.primary : Color.medicareBlue)
                .clipShape(Circle())
                .accessibilityHidden(true) // Icon is decorative

            Text(title)
                .font(.caption)
                .multilineTextAlignment(.center)
                .foregroundColor(colorScheme == .dark ? .white : .primary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(colorScheme == .dark ? Theme.dark.card : Color(.systemGray6))
        .cornerRadius(16)
        .shadow(color: colorScheme == .dark ? Theme.dark.shadow : .black.opacity(0.05), radius: 4, x: 0, y: 2)
        .minimumScaleFactor(0.8)
        .accessibilityAddTraits(.isButton)
    }
}

// MARK: - Appointments
struct CurrentAppointmentsSection: View {
    let appointments: [AppointmentData]
    @EnvironmentObject var appointmentManager: AppointmentManager
    @State private var selectedAppointment: AppointmentData? = nil
    @State private var appointmentToReschedule: AppointmentData? = nil
    @State private var showRescheduleModal = false
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            DashboardSectionHeader(title: "Current Appointments", destination: AllAppointmentsView())
                .accessibilityLabel("Current appointments section")

            ForEach(appointments.prefix(2)) { appointment in
                AppointmentCard(appointment: appointment)
                    .padding(.horizontal)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        self.selectedAppointment = appointment
                        self.appointmentToReschedule = nil
                        self.showRescheduleModal = false
                    }
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel("Appointment with \(appointment.doctorName)")
                    .accessibilityHint("Tap to view appointment details")
                    .accessibilityAddTraits(.isButton)
            }
        }
        .sheet(item: $selectedAppointment) { appointment in
            AppointmentSheetContents(
                appointment: appointment,
                showRescheduleModal: $showRescheduleModal,
                appointmentManager: appointmentManager,
                onDismiss: {
                    if !self.showRescheduleModal {
                        self.selectedAppointment = nil
                    }
                }
            )
            .accessibilityLabel("Appointment details")
            .onChange(of: self.showRescheduleModal) { newValue in
                if newValue {
                    self.appointmentToReschedule = appointment
                    self.selectedAppointment = nil
                }
            }
        }
        .sheet(isPresented: $showRescheduleModal) {
            if let appointmentForReschedule = self.appointmentToReschedule {
                AppointmentRescheduleView(appointment: appointmentForReschedule)
                    .accessibilityLabel("Reschedule appointment")
                    .onDisappear {
                        self.showRescheduleModal = false
                        self.appointmentToReschedule = nil
                    }
            } else {
                Text("No appointment selected for rescheduling")
                    .foregroundColor(colorScheme == .dark ? .white : .primary)
                    .accessibilityLabel("No appointment selected")
            }
        }
    }
}

struct AppointmentCard: View {
    let appointment: AppointmentData
    @Environment(\.colorScheme) var colorScheme
    
    var statusColor: Color {
        switch appointment.status {
        case .scheduled, .rescheduled: return .medicareBlue
        case .inProgress: return .medicareGreen
        case .completed: return .gray
        case .cancelled: return .medicareRed
        case .noShow: return .orange
        case .none:
            return .gray
        }
    }
    
    var statusText: String {
        switch appointment.status {
        case .scheduled: return "Scheduled"
        case .inProgress: return "In Progress"
        case .completed: return "Completed"
        case .cancelled: return "Cancelled"
        case .noShow: return "Waiting"
        case .rescheduled: return "Rescheduled"
        case .none:
            return "None"
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(appointment.doctorName)
                        .font(.headline)
                        .foregroundColor(colorScheme == .dark ? .white : .primary)
                    
                    if let dateTime = appointment.appointmentDateTime {
                        HStack {
                            Image(systemName: "calendar")
                                .foregroundColor(.gray)
                                .accessibilityHidden(true)
                            Text(dateTime, style: .date)
                                .foregroundColor(.gray)
                        }
                        .font(.subheadline)
                        
                        HStack {
                            Image(systemName: "clock")
                                .foregroundColor(.gray)
                                .accessibilityHidden(true)
                            Text(dateTime, style: .time)
                                .foregroundColor(.gray)
                        }
                        .font(.subheadline)
                    }
                }
                
                Spacer()
                
                Text(statusText)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(statusColor)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(statusColor.opacity(0.15))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(statusColor.opacity(0.3), lineWidth: 1)
                    )
                    .accessibilityLabel("Status: \(statusText)")
            }
            
            if let notes = appointment.notes {
                Text(notes)
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .lineLimit(2)
                    .accessibilityLabel("Notes: \(notes)")
            }
            
            HStack(spacing: 12) {
                Image(systemName: "stethoscope")
                    .foregroundColor(colorScheme == .dark ? Theme.dark.primary : .medicareBlue)
                    .accessibilityHidden(true)
                Text("Consultation")
                    .font(.subheadline)
                    .foregroundColor(colorScheme == .dark ? Theme.dark.primary : .medicareBlue)
                
                Spacer()
                
                if let duration = appointment.durationMinutes {
                    HStack(spacing: 4) {
                        Image(systemName: "clock.fill")
                            .font(.caption)
                            .foregroundColor(.gray)
                            .accessibilityHidden(true)
                        Text("\(duration) min")
                            .font(.caption)
                            .foregroundColor(.gray)
                            .accessibilityLabel("Duration: \(duration) minutes")
                    }
                }
            }
        }
        .padding()
        .background(colorScheme == .dark ? Theme.dark.card : Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 4)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.gray.opacity(0.1), lineWidth: 1)
        )
        .minimumScaleFactor(0.8)
    }
}

// MARK: - All Appointments View
struct AllAppointmentsView: View {
    @EnvironmentObject var appointmentManager: AppointmentManager
    @State private var selectedFilter: AppointmentFilter = .all
    @Environment(\.colorScheme) var colorScheme
    
    enum AppointmentFilter {
        case all, upcoming, completed, cancelled, waiting
        
        var title: String {
            switch self {
            case .all: return "All"
            case .upcoming: return "Upcoming"
            case .completed: return "Completed"
            case .cancelled: return "Cancelled"
            case .waiting: return "Waitlist"
            }
        }
    }
    
    var filteredAppointments: [AppointmentData] {
        switch selectedFilter {
        case .all:
            return appointmentManager.patientAppointments
        case .upcoming:
            return appointmentManager.patientAppointments.filter {
                $0.status == .scheduled || $0.status == .rescheduled || $0.status == .inProgress
            }
        case .completed:
            return appointmentManager.patientAppointments.filter { $0.status == .completed }
        case .cancelled:
            return appointmentManager.patientAppointments.filter {
                $0.status == .cancelled
            }
        case .waiting:
            return appointmentManager.patientAppointments.filter { $0.status == .noShow }
        }
    }
    
    var body: some View {
        VStack(spacing: 16) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach([AppointmentFilter.all, .upcoming, .completed, .cancelled, .waiting], id: \.title) { filter in
                        Button(action: { selectedFilter = filter }) {
                            Text(filter.title)
                                .font(.system(size: 14, weight: .medium))
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(
                                    selectedFilter == filter ?
                                        Color.medicareBlue :
                                        (colorScheme == .dark ? Color(.systemGray6) : Color(.systemGray6))
                                )
                                .foregroundColor(
                                    selectedFilter == filter ?
                                        .white :
                                        (colorScheme == .dark ? .white : .primary)
                                )
                                .clipShape(Capsule())
                                .overlay(
                                    Capsule()
                                        .stroke(
                                            selectedFilter == filter ?
                                                Color.medicareBlue :
                                                Color.medicareBlue.opacity(0.3),
                                            lineWidth: selectedFilter == filter ? 0 : 1
                                        )
                                )
                        }
                        .accessibilityLabel("Filter: \(filter.title)")
                        .accessibilityHint("Tap to filter appointments by \(filter.title)")
                        .accessibilityAddTraits(.isButton)
                    }
                }
                .padding(.horizontal)
            }
            .padding(.top, 8)
            .accessibilityLabel("Appointment filters")
            
            if appointmentManager.isLoading {
                ProgressView("Loading appointments")
                    .progressViewStyle(CircularProgressViewStyle())
                    .padding()
                    .accessibilityLabel("Loading appointments")
            } else if filteredAppointments.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "calendar.badge.exclamationmark")
                        .font(.system(size: 40))
                        .foregroundColor(.gray)
                        .accessibilityHidden(true)
                    Text("No appointments found")
                        .font(.headline)
                        .adaptiveTextColor()
                        .accessibilityLabel("No appointments found")
                    Text("There are no appointments in this category")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                        .accessibilityLabel("No appointments in this category")
                }
                .padding()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .themedCard()
            } else {
                ScrollView {
                    LazyVStack(spacing: 16) {
                        ForEach(filteredAppointments) { appointment in
                            AppointmentCard(appointment: appointment)
                                .padding(.horizontal)
                                .accessibilityElement(children: .combine)
                                .accessibilityLabel("Appointment with \(appointment.doctorName)")
                                .accessibilityHint("Tap to view appointment details")
                        }
                    }
                    .padding(.vertical)
                }
            }
        }
        .navigationTitle("Appointments")
        .navigationBarTitleDisplayMode(.inline)
        .primaryBackground()
        .accessibilityLabel("All appointments")
        .accessibilityHint("View and filter all your appointments")
    }
}

// MARK: - Reports
struct LatestReportsView: View {
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "chart.bar.doc.horizontal")
                    .foregroundColor(colorScheme == .dark ? Theme.dark.primary : .medicareBlue)
                    .font(.title3)
                    .accessibilityHidden(true)
                Text("Latest Reports")
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(colorScheme == .dark ? .white : .primary)
                    .accessibilityLabel("Latest reports section")
            }
            .padding(.horizontal)

            ReportCard(
                title: "Complete Blood Count",
                date: "May 15, 2023",
                status: "Within Range",
                icon: "drop.fill",
                iconBackground: Color.red.opacity(0.8)
            )
            ReportCard(
                title: "Chest X-Ray",
                date: "April 22, 2023",
                status: "No Abnormalities",
                icon: "lungs.fill",
                iconBackground: Color.blue.opacity(0.8)
            )
        }
        .accessibilityElement(children: .combine)
    }
}

struct ReportCard: View {
    let title: String
    let date: String
    let status: String
    let icon: String
    let iconBackground: Color
    @Environment(\.colorScheme) var colorScheme

    var statusColor: Color {
        status == "Within Range" || status == "No Abnormalities" ? .medicareGreen : .medicareRed
    }

    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(LinearGradient(
                        gradient: Gradient(colors: [iconBackground, iconBackground.opacity(0.7)]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))
                    .frame(width: 50, height: 50)
                
                Image(systemName: icon)
                    .foregroundColor(.white)
                    .font(.system(size: 24))
                    .accessibilityHidden(true)
            }

            VStack(alignment: .leading, spacing: 6) {
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(colorScheme == .dark ? .white : .primary)
                HStack {
                    Image(systemName: "calendar")
                        .font(.system(size: 12))
                        .foregroundColor(.gray)
                        .accessibilityHidden(true)
                    Text(date)
                        .font(.system(size: 14))
                        .foregroundColor(.gray)
                }
            }

            Spacer()

            Text(status)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(statusColor)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(statusColor.opacity(0.15))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(statusColor.opacity(0.3), lineWidth: 1)
                )
                .accessibilityLabel("Status: \(status)")
        }
        .padding()
        .background(colorScheme == .dark ? Theme.dark.card : Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 4)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.gray.opacity(0.1), lineWidth: 1)
        )
        .padding(.horizontal)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Report: \(title), dated \(date)")
        .minimumScaleFactor(0.8)
    }
}

// MARK: - Reminders
struct RemindersView: View {
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Reminders")
                .font(.headline)
                .foregroundColor(colorScheme == .dark ? .white : .primary)
                .padding(.horizontal)
                .accessibilityLabel("Reminders section")

            ReminderCard(title: "Take Metformin", time: "8:00 AM", isCompleted: true)
            ReminderCard(title: "Blood Pressure Check", time: "7:00 PM", isCompleted: false)
        }
        .accessibilityElement(children: .combine)
    }
}

struct ReminderCard: View {
    let title: String
    let time: String
    let isCompleted: Bool
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        HStack {
            Image(systemName: isCompleted ? "checkmark.circle.fill" : "circle")
                .foregroundColor(isCompleted ? .medicareGreen : .gray)
                .frame(width: 40)
                .accessibilityLabel(isCompleted ? "Completed" : "Not completed")
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .foregroundColor(isCompleted ? .gray : (colorScheme == .dark ? .white : .primary))
                    .strikethrough(isCompleted)
                Text(time)
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            
            Spacer()
        }
        .padding()
        .background(colorScheme == .dark ? Theme.dark.card : Color(.systemBackground))
        .cornerRadius(10)
        .shadow(color: Color.black.opacity(0.08), radius: 4, x: 0, y: 2)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color.gray.opacity(0.1), lineWidth: 1)
        )
        .padding(.horizontal)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Reminder: \(title) at \(time)")
        .accessibilityHint(isCompleted ? "Completed" : "Not completed")
        .minimumScaleFactor(0.8)
    }
}

// MARK: - Reusable Section Header
struct DashboardSectionHeader<Destination: View>: View {
    let title: String
    let destination: Destination
    @EnvironmentObject var appointmentManager: AppointmentManager
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        HStack {
            Text(title)
                .font(.headline)
                .foregroundColor(colorScheme == .dark ? .white : .primary)

            Spacer()

            NavigationLink(destination: destination.environmentObject(appointmentManager)) {
                Text("View All")
                    .font(.subheadline)
                    .foregroundColor(colorScheme == .dark ? Theme.dark.primary : .medicareBlue)
                    .accessibilityLabel("View all \(title.lowercased())")
                    .accessibilityHint("Tap to view all items in this section")
                    .accessibilityAddTraits(.isButton)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal)
        .accessibilityElement(children: .combine)
    }
}
