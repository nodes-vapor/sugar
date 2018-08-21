import Vapor
import Validation

public struct JSONValidator: Validator {

    public func validate(_ input: String) throws {
        do {
            _ = try JSON(bytes: input.makeBytes())
        } catch {
            throw self.error("Invalid JSON.")
        }
    }
}