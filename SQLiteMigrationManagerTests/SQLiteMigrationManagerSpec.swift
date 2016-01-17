import Quick
import Nimble
import SQLiteMigrationManager

class SQLiteMigrationManagerSpec: QuickSpec {
  override func spec() {
    var subject: SQLiteMigrationManager!

    beforeEach {
      subject = SQLiteMigrationManager()
    }

    describe("helloWorld") {
      it("returns Hello World!") {
        expect(subject.helloWorld()).to(equal("Hello World!"))
      }
    }
  }
}
