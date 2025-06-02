error id: file://<WORKSPACE>/backend/src/main/scala/Main.scala:`<none>`.
file://<WORKSPACE>/backend/src/main/scala/Main.scala
empty definition using pc, found symbol in pc: `<none>`.
empty definition using semanticdb
empty definition using fallback
non-local guesses:
	 -akka/http/scaladsl/server/Directives.Completed.
	 -akka/http/scaladsl/server/Directives.Completed#
	 -akka/http/scaladsl/server/Directives.Completed().
	 -io/circe/generic/auto/Completed.
	 -io/circe/generic/auto/Completed#
	 -io/circe/generic/auto/Completed().
	 -de/heikoseeberger/akkahttpcirce/FailFastCirceSupport.Completed.
	 -de/heikoseeberger/akkahttpcirce/FailFastCirceSupport.Completed#
	 -de/heikoseeberger/akkahttpcirce/FailFastCirceSupport.Completed().
	 -org/mongodb/scala/Completed.
	 -org/mongodb/scala/Completed#
	 -org/mongodb/scala/Completed().
	 -org/mongodb/scala/model/Filters.Completed.
	 -org/mongodb/scala/model/Filters.Completed#
	 -org/mongodb/scala/model/Filters.Completed().
	 -ch/megard/akka/http/cors/scaladsl/CorsDirectives.Completed.
	 -ch/megard/akka/http/cors/scaladsl/CorsDirectives.Completed#
	 -ch/megard/akka/http/cors/scaladsl/CorsDirectives.Completed().
	 -Completed.
	 -Completed#
	 -Completed().
	 -scala/Predef.Completed.
	 -scala/Predef.Completed#
	 -scala/Predef.Completed().
offset: 439
uri: file://<WORKSPACE>/backend/src/main/scala/Main.scala
text:
```scala
import akka.actor.ActorSystem
import akka.http.scaladsl.Http
import akka.http.scaladsl.server.Directives._
import io.circe.generic.auto._
import de.heikoseeberger.akkahttpcirce.FailFastCirceSupport._
import org.mongodb.scala._
import org.mongodb.scala.model.Filters._

import ch.megard.akka.http.cors.scaladsl.CorsDirectives._ // 🔥 Required for CORS
import ch.megard.akka.http.cors.scaladsl.settings.CorsSettings
import org.mongodb.scala.@@Completed

import scala.concurrent.ExecutionContextExecutor
import scala.io.StdIn

final case class LeaveApplication(name: String, fromDate: String, toDate: String, reason: String)

object Main {
  def main(args: Array[String]): Unit = {
    implicit val system: ActorSystem = ActorSystem("leave-system")
    implicit val executionContext: ExecutionContextExecutor = system.dispatcher

    val mongoClient: MongoClient = MongoClient("mongodb://127.0.0.1:27017")
    val database: MongoDatabase = mongoClient.getDatabase("leave_db")
    val collection: MongoCollection[Document] = database.getCollection("applications")

    val route =
      cors() {
        path("apply-leave") {
          post {
            entity(as[LeaveApplication]) { application =>
              println(s"Received: $application")

              val doc: Document = Document(
                "name" -> application.name,
                "fromDate" -> application.fromDate,
                "toDate" -> application.toDate,
                "reason" -> application.reason
              )

              collection.insertOne(doc).subscribe(new Observer[Completed] {
                override def onNext(result: Completed): Unit = println("Inserted")
                override def onError(e: Throwable): Unit = println("Failed: " + e.getMessage)
                override def onComplete(): Unit = println("Completed")
              })

              complete("Application received")
            }
          }
        }
      }

    val bindingFuture = Http().newServerAt("localhost", 8080).bind(route)

    println("Server online at http://localhost:8080/")
    StdIn.readLine()
    bindingFuture
      .flatMap(_.unbind())
      .onComplete(_ => system.terminate())
  }
}

```


#### Short summary: 

empty definition using pc, found symbol in pc: `<none>`.