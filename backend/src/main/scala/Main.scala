import akka.actor.ActorSystem
import akka.http.scaladsl.Http
import akka.http.scaladsl.model.StatusCodes
import akka.http.scaladsl.server.Directives._
import io.circe.generic.auto._
import de.heikoseeberger.akkahttpcirce.FailFastCirceSupport._
import org.mongodb.scala._
import org.mongodb.scala.model.Filters._
import org.mongodb.scala.model.Updates._
import org.mongodb.scala.model._
import ch.megard.akka.http.cors.scaladsl.CorsDirectives._
import ch.megard.akka.http.cors.scaladsl.settings.CorsSettings
import akka.http.scaladsl.model.HttpMethods._
import scala.concurrent.Future
import scala.concurrent.ExecutionContext.Implicits.global
import scala.concurrent.ExecutionContextExecutor
import scala.io.StdIn
import scala.util.{Failure, Success}
import akka.http.scaladsl.server.Directives._

// Case class definitions for Library Management System
case class Librarian(id: String, name: String, specialty: String)
case class BookRequest(id: String, memberId: String, librarianId: String, bookId: String, date: String, time: String, status: String)
case class Staff(id: String, name: String, role: String, department: String)
case class Member(id: String, name: String, email: String, phone: String, address: String)
case class Book(id: String, title: String, author: String, isbn: String, quantity: Int, available: Int)
case class User(id: String, username: String, email: String, password: String, role: String)

// Legacy case classes for backward compatibility
case class Doctor(id: String, name: String, specialty: String)
case class Appointment(id: String, patientId: String, doctorId: String, date: String, time: String)

object Main {
  def main(args: Array[String]): Unit = {
    implicit val system: ActorSystem = ActorSystem("library-management-system")
    implicit val ec: ExecutionContextExecutor = system.dispatcher

    val mongoClient: MongoClient = MongoClient("mongodb://127.0.0.1:27017")
    val database: MongoDatabase = mongoClient.getDatabase("library_db")
    
    // Library Management Collections
    val librarianCollection: MongoCollection[Document] = database.getCollection("librarians")
    val bookRequestCollection: MongoCollection[Document] = database.getCollection("book_requests")
    val staffCollection: MongoCollection[Document] = database.getCollection("staff")
    val memberCollection: MongoCollection[Document] = database.getCollection("members")
    val inventoryCollection: MongoCollection[Document] = database.getCollection("inventory")
    val userCollection: MongoCollection[Document] = database.getCollection("users")
    
    // Legacy collections for backward compatibility
    val doctorCollection: MongoCollection[Document] = database.getCollection("doctors")
    val appointmentCollection: MongoCollection[Document] = database.getCollection("appointments")

    // Document conversion functions
    def docFromLibrarian(l: Librarian): Document =
      Document("id" -> l.id, "name" -> l.name, "specialty" -> l.specialty)

    def docFromBookRequest(br: BookRequest): Document =
      Document("id" -> br.id, "memberId" -> br.memberId, "librarianId" -> br.librarianId, "bookId" -> br.bookId, "date" -> br.date, "time" -> br.time, "status" -> br.status)

    def docFromStaff(s: Staff): Document =
      Document("id" -> s.id, "name" -> s.name, "role" -> s.role, "department" -> s.department)

    def docFromMember(m: Member): Document =
      Document("id" -> m.id, "name" -> m.name, "email" -> m.email, "phone" -> m.phone, "address" -> m.address)

    def docFromBook(b: Book): Document =
      Document("id" -> b.id, "title" -> b.title, "author" -> b.author, "isbn" -> b.isbn, "quantity" -> b.quantity, "available" -> b.available)

    def docFromUser(u: User): Document =
      Document("id" -> u.id, "username" -> u.username, "email" -> u.email, "password" -> u.password, "role" -> u.role)

    // Legacy compatibility functions
    def docFromDoctor(d: Doctor): Document =
      Document("id" -> d.id, "name" -> d.name, "specialty" -> d.specialty)

    def docFromAppointment(a: Appointment): Document =
      Document("id" -> a.id, "patientId" -> a.patientId, "doctorId" -> a.doctorId, "date" -> a.date, "time" -> a.time)

    val corsSettings = CorsSettings.defaultSettings.withAllowedMethods(Seq(GET, POST, PUT, DELETE, OPTIONS))

    val route =
      cors(corsSettings) {
        concat(
          // === User Authentication ===
          pathPrefix("users") {
            concat(
              pathPrefix("signup") {
                post {
                  entity(as[User]) { user =>
                    userCollection.insertOne(docFromUser(user)).toFuture()
                    complete(StatusCodes.Created, s"User ${user.username} registered successfully.")
                  }
                }
              },
              pathEndOrSingleSlash {
                get {
                  complete {
                    userCollection.find().toFuture().map(_.map(_.toJson()))
                  }
                }
              },
              path(Segment) { id =>
                get {
                  complete {
                    userCollection.find(equal("id", id)).first().toFuture().map(_.toJson())
                  }
                }
              }
            )
          },

          // === Member Management (formerly Patients) ===
          pathPrefix("members") {
            concat(
              post {
                entity(as[Member]) { member =>
                  memberCollection.insertOne(docFromMember(member)).toFuture()
                  complete(StatusCodes.Created, s"Member ${member.name} added.")
                }
              },
              get {
                path(Segment) { id =>
                  complete {
                    memberCollection.find(equal("id", id)).first().toFuture().map(_.toJson())
                  }
                } ~
                pathEndOrSingleSlash {
                  complete {
                    memberCollection.find().toFuture().map(_.map(_.toJson()))
                  }
                }
              },
              put {
                path(Segment) { id =>
                  entity(as[Member]) { updated =>
                    memberCollection.updateOne(equal("id", id), combine(
                      set("name", updated.name),
                      set("email", updated.email),
                      set("phone", updated.phone),
                      set("address", updated.address)
                    )).toFuture()
                    complete(StatusCodes.OK, s"Member $id updated.")
                  }
                }
              },
              path(Segment) { id =>
                delete {
                  memberCollection.deleteOne(equal("id", id)).toFuture()
                  complete(StatusCodes.OK, s"Member $id deleted.")
                }
              }
            )
          },

          // === Librarian Management (formerly Doctors) ===
          pathPrefix("librarians") {
            concat(
              post {
                entity(as[Librarian]) { librarian =>
                  librarianCollection.insertOne(docFromLibrarian(librarian)).toFuture()
                  complete(StatusCodes.Created, s"Librarian ${librarian.name} added.")
                }
              },
              get {
                path(Segment) { id =>
                  complete {
                    librarianCollection.find(equal("id", id)).first().toFuture().map(_.toJson())
                  }
                } ~
                pathEndOrSingleSlash {
                  complete {
                    librarianCollection.find().toFuture().map(_.map(_.toJson()))
                  }
                }
              },
              put {
                path(Segment) { id =>
                  entity(as[Librarian]) { updated =>
                    librarianCollection.updateOne(equal("id", id), combine(
                      set("name", updated.name),
                      set("specialty", updated.specialty)
                    )).toFuture()
                    complete(StatusCodes.OK, s"Librarian $id updated.")
                  }
                }
              },
              path(Segment) { id =>
                delete {
                  librarianCollection.deleteOne(equal("id", id)).toFuture()
                  complete(StatusCodes.OK, s"Librarian $id deleted.")
                }
              }
            )
          },

          // === Book Request Management (formerly Appointments) ===
          pathPrefix("book-requests") {
            concat(
              post {
                entity(as[BookRequest]) { request =>
                  bookRequestCollection.insertOne(docFromBookRequest(request)).toFuture()
                  complete(StatusCodes.Created, s"Book request ${request.id} created.")
                }
              },
              get {
                path(Segment) { id =>
                  complete {
                    bookRequestCollection.find(equal("id", id)).first().toFuture().map(_.toJson())
                  }
                } ~
                pathEndOrSingleSlash {
                  complete {
                    bookRequestCollection.find().toFuture().map(_.map(_.toJson()))
                  }
                }
              },
              put {
                path(Segment) { id =>
                  entity(as[BookRequest]) { updated =>
                    bookRequestCollection.updateOne(equal("id", id), combine(
                      set("memberId", updated.memberId),
                      set("librarianId", updated.librarianId),
                      set("bookId", updated.bookId),
                      set("date", updated.date),
                      set("time", updated.time),
                      set("status", updated.status)
                    )).toFuture()
                    complete(StatusCodes.OK, s"Book request $id updated.")
                  }
                }
              },
              path(Segment) { id =>
                delete {
                  bookRequestCollection.deleteOne(equal("id", id)).toFuture()
                  complete(StatusCodes.OK, s"Book request $id cancelled.")
                }
              }
            )
          },

          // === Borrowed Books Tracking ===
          pathPrefix("borrowed-books") {
            get {
              complete {
                // Get all borrowed books (status = "borrowed")
                bookRequestCollection.find(equal("status", "borrowed")).toFuture().map { requests =>
                  requests.map(_.toJson())
                }
              }
            }
          },

          // === Book Inventory Management (formerly Pharmacy) ===
          pathPrefix("inventory") {
            concat(
              post {
                entity(as[Book]) { book =>
                  inventoryCollection.insertOne(docFromBook(book)).toFuture()
                  complete(StatusCodes.Created, s"Book ${book.title} added to inventory.")
                }
              },
              get {
                path(Segment) { id =>
                  complete {
                    inventoryCollection.find(equal("id", id)).first().toFuture().map(_.toJson())
                  }
                } ~
                pathEndOrSingleSlash {
                  complete {
                    inventoryCollection.find().toFuture().map(_.map(_.toJson()))
                  }
                }
              },
              put {
                path(Segment) { id =>
                  entity(as[Book]) { updated =>
                    inventoryCollection.updateOne(equal("id", id), combine(
                      set("title", updated.title),
                      set("author", updated.author),
                      set("isbn", updated.isbn),
                      set("quantity", updated.quantity),
                      set("available", updated.available)
                    )).toFuture()
                    complete(StatusCodes.OK, s"Book $id updated.")
                  }
                }
              },
              path(Segment) { id =>
                delete {
                  inventoryCollection.deleteOne(equal("id", id)).toFuture()
                  complete(StatusCodes.OK, s"Book $id removed from inventory.")
                }
              }
            )
          },

          // === Staff Management ===
          pathPrefix("staff") {
            concat(
              post {
                entity(as[Staff]) { staff =>
                  staffCollection.insertOne(docFromStaff(staff)).toFuture()
                  complete(StatusCodes.Created, s"Staff ${staff.name} added.")
                }
              },
              get {
                path(Segment) { id =>
                  complete {
                    staffCollection.find(equal("id", id)).first().toFuture().map(_.toJson())
                  }
                } ~
                pathEndOrSingleSlash {
                  complete {
                    staffCollection.find().toFuture().map(_.map(_.toJson()))
                  }
                }
              },
              put {
                path(Segment) { id =>
                  entity(as[Staff]) { updated =>
                    val updateStaff = staffCollection.updateOne(equal("id", id), combine(
                      set("name", updated.name),
                      set("role", updated.role),
                      set("department", updated.department)
                    )).toFuture()

                    val updateLibrarianTable =
                      if (updated.role.toLowerCase == "librarian") {
                        librarianCollection.updateOne(equal("id", id), combine(
                          set("name", updated.name),
                          set("specialty", updated.department)
                        )).toFuture()
                      } else {
                        Future.successful(())
                      }

                    onSuccess(for {
                      _ <- updateStaff
                      _ <- updateLibrarianTable
                    } yield ()) {
                      complete(StatusCodes.OK, s"Staff $id updated.")
                    }
                  }
                }
              },
              path(Segment) { id =>
                delete {
                  staffCollection.deleteOne(equal("id", id)).toFuture()
                  complete(StatusCodes.OK, s"Staff $id deleted.")
                }
              }
            )
          },

          // === Legacy Endpoints for Backward Compatibility ===
          pathPrefix("doctors") {
            concat(
              post {
                entity(as[Doctor]) { doctor =>
                  doctorCollection.insertOne(docFromDoctor(doctor)).toFuture()
                  complete(StatusCodes.Created, s"Doctor ${doctor.name} added.")
                }
              },
              get {
                path(Segment) { id =>
                  complete {
                    doctorCollection.find(equal("id", id)).first().toFuture().map(_.toJson())
                  }
                } ~
                pathEndOrSingleSlash {
                  complete {
                    doctorCollection.find().toFuture().map(_.map(_.toJson()))
                  }
                }
              },
              put {
                path(Segment) { id =>
                  entity(as[Doctor]) { updated =>
                    doctorCollection.updateOne(equal("id", id), combine(
                      set("name", updated.name),
                      set("specialty", updated.specialty)
                    )).toFuture()
                    complete(StatusCodes.OK, s"Doctor $id updated.")
                  }
                }
              },
              path(Segment) { id =>
                delete {
                  doctorCollection.deleteOne(equal("id", id)).toFuture()
                  complete(StatusCodes.OK, s"Doctor $id deleted.")
                }
              }
            )
          },

          pathPrefix("appointments") {
            concat(
              post {
                entity(as[Appointment]) { appt =>
                  appointmentCollection.insertOne(docFromAppointment(appt)).toFuture()
                  complete(StatusCodes.Created, s"Appointment ${appt.id} booked.")
                }
              },
              get {
                path(Segment) { id =>
                  complete {
                    appointmentCollection.find(equal("id", id)).first().toFuture().map(_.toJson())
                  }
                } ~
                pathEndOrSingleSlash {
                  complete {
                    appointmentCollection.find().toFuture().map(_.map(_.toJson()))
                  }
                }
              },
              put {
                path(Segment) { id =>
                  entity(as[Appointment]) { updated =>
                    appointmentCollection.updateOne(equal("id", id), combine(
                      set("patientId", updated.patientId),
                      set("doctorId", updated.doctorId),
                      set("date", updated.date),
                      set("time", updated.time)
                    )).toFuture()
                    complete(StatusCodes.OK, s"Appointment $id updated.")
                  }
                }
              },
              path(Segment) { id =>
                delete {
                  appointmentCollection.deleteOne(equal("id", id)).toFuture()
                  complete(StatusCodes.OK, s"Appointment $id cancelled.")
                }
              }
            )
          },

          // === Pharmacy endpoint for backward compatibility ===
          pathPrefix("pharmacy") {
            concat(
              post {
                entity(as[Book]) { book =>
                  inventoryCollection.insertOne(docFromBook(book)).toFuture()
                  complete(StatusCodes.Created, s"Item ${book.title} added.")
                }
              },
              get {
                path(Segment) { id =>
                  complete {
                    inventoryCollection.find(equal("id", id)).first().toFuture().map(_.toJson())
                  }
                } ~
                pathEndOrSingleSlash {
                  complete {
                    inventoryCollection.find().toFuture().map(_.map(_.toJson()))
                  }
                }
              },
              put {
                path(Segment) { id =>
                  entity(as[Book]) { updated =>
                    inventoryCollection.updateOne(equal("id", id), combine(
                      set("title", updated.title),
                      set("author", updated.author),
                      set("isbn", updated.isbn),
                      set("quantity", updated.quantity),
                      set("available", updated.available)
                    )).toFuture()
                    complete(StatusCodes.OK, s"Item $id updated.")
                  }
                }
              },
              path(Segment) { id =>
                delete {
                  inventoryCollection.deleteOne(equal("id", id)).toFuture()
                  complete(StatusCodes.OK, s"Item $id removed.")
                }
              }
            )
          }
        )
      }

    val bindingFuture = Http().newServerAt("localhost", 8080).bind(route)
    println("Library Management System online at http://localhost:8080/")
    StdIn.readLine()
    bindingFuture.flatMap(_.unbind()).onComplete(_ => system.terminate())
  }
}
