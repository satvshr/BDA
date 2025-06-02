document.getElementById("registrationForm").addEventListener("submit", async (e) => {
  e.preventDefault();

  const data = {
    name: document.getElementById("name").value,
    email: document.getElementById("email").value,
    eventName: document.getElementById("eventName").value,
  };

  const response = await fetch("http://localhost:8080/register", {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify(data),
  });

  if (response.ok) {
    alert("Registration submitted!");
    e.target.reset(); // reset form
  } else {
    alert("Failed to submit registration.");
  }
});
