import Foundation

// MARK: - Exercise

struct Exercise: Identifiable {
    let id = UUID()
    let name: String
    let sets: Int
    let reps: String        // "12" or "30 сек"
    let rest: String        // "60 сек" or "—"
    let muscleGroup: String
    let icon: String        // SF Symbol name
}

// MARK: - WorkoutType

enum WorkoutType {
    case rest, mobility, cardio, strengthLight, strengthHeavy

    init(workoutType: String, intensity: String) {
        switch workoutType.lowercased() {
        case "йога", "yoga", "розтяжка", "mobility":
            self = .mobility
        case "hiit", "кардіо", "cardio":
            self = .cardio
        case "силове", "strength", "силове тренування":
            self = intensity.lowercased().contains("висок") ? .strengthHeavy : .strengthLight
        case "rest", "відпочинок":
            self = .rest
        default:
            self = .rest
        }
    }
}

// MARK: - WorkoutLibrary

struct WorkoutLibrary {

    static func exercises(for workoutType: String, intensity: String) -> [Exercise] {
        exercises(for: WorkoutType(workoutType: workoutType, intensity: intensity))
    }

    static func exercises(for type: WorkoutType) -> [Exercise] {
        switch type {
        case .rest:
            return []

        case .mobility:
            return [
                Exercise(name: "Кругові рухи шиєю",      sets: 2, reps: "30 сек", rest: "15 сек", muscleGroup: "Шия",   icon: "figure.flexibility"),
                Exercise(name: "Розтяжка грудей",         sets: 2, reps: "30 сек", rest: "15 сек", muscleGroup: "Груди", icon: "figure.arms.open"),
                Exercise(name: "Нахили вперед",           sets: 3, reps: "20 сек", rest: "20 сек", muscleGroup: "Спина", icon: "figure.cooldown"),
                Exercise(name: "Котячо-коров'яча поза",   sets: 2, reps: "45 сек", rest: "20 сек", muscleGroup: "Спина", icon: "figure.mind.and.body"),
                Exercise(name: "Піраміда",                sets: 3, reps: "30 сек", rest: "20 сек", muscleGroup: "Ноги",  icon: "triangle"),
            ]

        case .cardio:
            return [
                Exercise(name: "Розминка ходьба",          sets: 1, reps: "5 хв",   rest: "—",      muscleGroup: "Загальне",    icon: "figure.walk"),
                Exercise(name: "Стрибки на місці",         sets: 3, reps: "45 сек", rest: "30 сек", muscleGroup: "Ноги",        icon: "figure.jumprope"),
                Exercise(name: "Присідання з вагою тіла",  sets: 4, reps: "15",     rest: "45 сек", muscleGroup: "Квадріцепс", icon: "figure.squat"),
                Exercise(name: "Берпі",                    sets: 3, reps: "10",     rest: "60 сек", muscleGroup: "Загальне",    icon: "bolt.fill"),
                Exercise(name: "Бічні стрибки",            sets: 3, reps: "30 сек", rest: "30 сек", muscleGroup: "Ноги",        icon: "arrow.left.arrow.right"),
                Exercise(name: "Заминка",                  sets: 1, reps: "5 хв",   rest: "—",      muscleGroup: "Загальне",    icon: "figure.cooldown"),
            ]

        case .strengthLight:
            return [
                Exercise(name: "Жим гантелей лежачи",  sets: 4, reps: "12",     rest: "75 сек", muscleGroup: "Груди",                 icon: "dumbbell.fill"),
                Exercise(name: "Тяга до підборіддя",   sets: 3, reps: "12",     rest: "60 сек", muscleGroup: "Плечі",                 icon: "figure.strengthtraining.traditional"),
                Exercise(name: "Присідання",           sets: 4, reps: "12",     rest: "75 сек", muscleGroup: "Ноги",                  icon: "figure.squat"),
                Exercise(name: "Жим гантелей сидячи", sets: 3, reps: "12",     rest: "60 сек", muscleGroup: "Плечі",                 icon: "dumbbell"),
                Exercise(name: "Планка",               sets: 3, reps: "45 сек", rest: "45 сек", muscleGroup: "Кор",                   icon: "figure.core.training"),
                Exercise(name: "Румунська тяга",       sets: 3, reps: "12",     rest: "75 сек", muscleGroup: "Задня поверхня стегна", icon: "figure.strengthtraining.functional"),
            ]

        case .strengthHeavy:
            return [
                Exercise(name: "Присідання зі штангою", sets: 5, reps: "5",      rest: "180 сек", muscleGroup: "Ноги",  icon: "figure.squat"),
                Exercise(name: "Жим лежачи",            sets: 5, reps: "5",      rest: "180 сек", muscleGroup: "Груди", icon: "dumbbell.fill"),
                Exercise(name: "Станова тяга",          sets: 4, reps: "5",      rest: "240 сек", muscleGroup: "Спина", icon: "figure.strengthtraining.traditional"),
                Exercise(name: "Підтягування",          sets: 4, reps: "MAX",    rest: "120 сек", muscleGroup: "Спина", icon: "figure.pull.ups"),
                Exercise(name: "Жим плечима",           sets: 4, reps: "8",      rest: "120 сек", muscleGroup: "Плечі", icon: "dumbbell"),
                Exercise(name: "Планка з обтяженням",   sets: 3, reps: "60 сек", rest: "90 сек",  muscleGroup: "Кор",   icon: "figure.core.training"),
            ]
        }
    }
}
