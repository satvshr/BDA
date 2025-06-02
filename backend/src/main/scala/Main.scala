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

import scala.concurrent.ExecutionContextExecutor
import scala.io.StdIn
import scala.util.{Failure, Success}

// === Case Classes ===
final case class Doctor(id: String, name: String, specialty: String)
final case class Appointment(id: String, patientId: String, doctorId: String, date: String, time: String)
final case class Staff(id: String, name: String, role: String, department: String)

object Main {
  def main(args: Array[String]): Unit = {
    implicit val system: ActorSystem = ActorSystem("hospital-management-system")
    implicit val ec: ExecutionContextExecutor = system.dispatcher

    val mongoClient: MongoClient = MongoClient("mongodb://127.0.0.1:27017")
    val database: MongoDatabase = mongoClient.getDatabase("hospital_db")
    val doctorCollection: MongoCollection[Document] = database.getCollection("doctors")
    val appointmentCollection: MongoCollection[Document] = database.getCollection("appointments")
    val staffCollection: MongoCollection[Document] = database.getCollection("staff")

    def docFromDoctor(d: Doctor): Document =
      Document("id" -> d.id, "name" -> d.name, "specialty" -> d.specialty)

    def docFromAppointment(a: Appointment): Document =
      Document("id" -> a.id, "patientId" -> a.patientId, "doctorId" -> a.doctorId, "date" -> a.date, "time" -> a.time)

    def docFromStaff(s: Staff): Document =
      Document("id" -> s.id, "name" -> s.name, "role" -> s.role, "department" -> s.department)

    val corsSettings = CorsSettings.defaultSettings.withAllowedMethods(Seq(GET, POST, PUT, DELETE, OPTIONS))

    val route =
      cors(corsSettings) {
        concat(
          // === Doctor CRUD ===
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
              delete {
                path(Segment) { id =>
                  doctorCollection.deleteOne(equal("id", id)).toFuture()
                  complete(StatusCodes.OK, s"Doctor $id deleted.")
                }
              }
            )
          },

          // === Appointment CRUD ===
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
              delete {
                path(Segment) { id =>
                  appointmentCollection.deleteOne(equal("id", id)).toFuture()
                  complete(StatusCodes.OK, s"Appointment $id cancelled.")
                }
              }
            )
          },

          // === Staff CRUD ===
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

                  val updateDoctorTable =
                    if (updated.department.toLowerCase == "doctor") {
                      doctorCollection.updateOne(equal("id", id), combine(
                        set("name", updated.name),
                        set("specialty", "Updated by staff update") // Adjust logic or extract from Staff if available
                      )).toFuture()
                    } else {
                      Future.successful(())
                    }

                  onSuccess(for {
                    _ <- updateStaff
                    _ <- updateDoctorTable
                  } yield ()) {
                    complete(StatusCodes.OK, s"Staff $id updated.")
                  }
                }
              }
            }

              delete {
                path(Segment) { id =>
                  staffCollection.deleteOne(equal("id", id)).toFuture()
                  complete(StatusCodes.OK, s"Staff $id deleted.")
                }
              }
            )
          }
        )
      }

    val bindingFuture = Http().newServerAt("localhost", 8080).bind(route)
    println("Hospital Management System online at http://localhost:8080/")
    StdIn.readLine()
    bindingFuture.flatMap(_.unbind()).onComplete(_ => system.terminate())
  }
}
