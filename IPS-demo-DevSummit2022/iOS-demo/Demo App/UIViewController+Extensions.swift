import UIKit

extension UIViewController {
    /// Shows an alert with the given title, message, and an OK button.
    func presentAlert(title: String? = nil, message: String? = nil) {
        let okAction = UIAlertAction(title: "OK", style: .default)
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert, actions: [okAction])
        present(alertController, animated: true)
    }
    
    /// Show an alert with the title "Error", the error's `localizedDescription`
    /// as the message, and an OK button.
    func presentAlert(error: Error) {
        presentAlert(title: "Error", message: error.localizedDescription)
    }
}

private extension UIAlertController {
    /// Initializes the alert controller with the given parameters, adding the
    /// actions successively and setting the first action as preferred.
    convenience init(title: String? = nil, message: String? = nil, preferredStyle: UIAlertController.Style = .alert, actions: [UIAlertAction] = []) {
        self.init(title: title, message: message, preferredStyle: preferredStyle)
        for action in actions {
            addAction(action)
        }
        preferredAction = actions.first
    }
}
