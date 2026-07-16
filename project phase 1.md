The GlobeTrotter Project – Your Semester Mission
1 Project Overview
Throughout this semester, you will build the GlobeTrotter Travel Assistant —a distributed travel recommendation application—.
This project is designed to give you hands-on experience with every
concept covered in this course, from monolithic architecture to
production-grade distributed systems.
Business Requirements:
• Users can search for travel destinations and get personalized recommendations. • Users can create, view, and manage travel itineraries. • Users can share itineraries with friends and family. • The system must handle millions of users globally. • Recommendations should be based on user preferences,
past trips, and popular destinations. • The system should be available 24/7 with minimal downtime.
Technical Requirements:
• Must be scalable to millions of users. • Must be resilient to failures (no single point of failure). • Must support rapid iteration and deployment. • Must be cost-effective (pay only for what you use). • Must be observable (metrics, logging, tracing).
Project Timeline:
Phase Completion
Phase 1: Monolith End of Class 3
Phase 2: Microservices End of Class 5
Phase 3: Cloud Deployment End of Class 8
Phase 4: Resilience End of Class 10
Key Insight: GlobeTrotter is not just a class project—it is a portfolio project that demonstrates your understanding of distributed systems.
By the end of the semester, you will have built a system that you can
show to potential employers.
2 The Four Phases at a Glance
The project progresses through four phases, each building on the
previous one:
Phase Key Learning Outcomes
Phase 1: Monolith
Understand the limitations of centralized architectures. Build a
working REST API.
Phase 2: Microservices
Learn service decomposition, interservice communication, and API
design.
Phase 3: Cloud Deployment
Experience containerization, load
balancing, auto-scaling, and cloud
deployment.
Phase 4: Resilience Implement caching, message
queues, circuit breakers, and fault
tolerance.
Key Insight: Each phase introduces new challenges that mirror
real-world problems. You will learn by solving these problems—not
by memorizing theory. The project is designed to be incremental, so you can build confidence as you progress.
Engr. Daniel Moune (ICT-U) CS 4122 76 / 84
Introduction - Why Distributed Systems
Distributed Systems - Models and Architectures
Cloud Models – IaaS, PaaS, SaaS Cloud Deployment Models – Public, Private, HCapstone Project – The Globetrotter Project Lab Setup – Setting up with DockeThe GlobeTrotter Project – Your Semester Mission
1 Project Overview
Throughout this semester, you will build the GlobeTrotter Travel Assistant —a distributed travel recommendation application—.
This project is designed to give you hands-on experience with every
concept covered in this course, from monolithic architecture to
production-grade distributed systems.
Business Requirements:
• Users can search for travel destinations and get personalized recommendations. • Users can create, view, and manage travel itineraries. • Users can share itineraries with friends and family. • The system must handle millions of users globally. • Recommendations should be based on user preferences,
past trips, and popular destinations. • The system should be available 24/7 with minimal downtime.
Technical Requirements:
• Must be scalable to millions of users. • Must be resilient to failures (no single point of failure). • Must support rapid iteration and deployment. • Must be cost-effective (pay only for what you use). • Must be observable (metrics, logging, tracing).
Project Timeline:
Phase Completion
Phase 1: Monolith End of Class 3
Phase 2: Microservices End of Class 5
Phase 3: Cloud Deployment End of Class 8
Phase 4: Resilience End of Class 10
Key Insight: GlobeTrotter is not just a class project—it is a portfolio project that demonstrates your understanding of distributed systems.
By the end of the semester, you will have built a system that you can
show to potential employers.
2 The Four Phases at a Glance
The project progresses through four phases, each building on the
previous one:
Phase Key Learning Outcomes
Phase 1: Monolith
Understand the limitations of centralized architectures. Build a
working REST API.
Phase 2: Microservices
Learn service decomposition, interservice communication, and API
design.
Phase 3: Cloud Deployment
Experience containerization, load
balancing, auto-scaling, and cloud
deployment.
Phase 4: Resilience Implement caching, message
queues, circuit breakers, and fault
tolerance.
Key Insight: Each phase introduces new challenges that mirror
real-world problems. You will learn by solving these problems—not
by memorizing theory. The project is designed to be incremental, so you can build confidence as you progress.
Engr. Daniel Moune (ICT-U) CS 4122 76 / 84
Introduction - Why Distributed Systems
Distributed Systems - Models and Architectures
Cloud Models – IaaS, PaaS, SaaS Cloud Deployment Models – Public, Private, HCapstone Project – The Globetrotter Project Lab Setup – Setting up with DockePhase 1 – The Monolith
1 Architecture Overview
In Phase 1, you will build a monolithic application—a single server
handling all requests with data stored in a JSON file. This phase
demonstrates the limitations of centralized architectures and provides a baseline for comparison.
Architecture Diagram:
GlobeTrotter Monolith
API
Business Logic
Data Access
Client JSON File
Components:
• API Layer: REST endpoints for user registration, login,
destination search, itinerary management. • Business Logic: Algorithms for recommendations, trip
planning, and user preferences. • Data Access: Read and write to a JSON file (no database yet). • Authentication: Simple JWT-based authentication.
Technology Stack:
• Backend: Python (Flask or FastAPI) or Node.js (Ex- press) • Data: JSON file storage (no database) • Testing: pytest or Jest • Version Control: Git (each team creates a repository)
Endpoints to Implement:
• ‘POST /register‘ – Register a new user • ‘POST /login‘ – Authenticate a user • ‘GET /destinations‘ – Search destinations • ‘GET /recommendations‘ – Get personalized recommendations • ‘POST /itineraries‘ – Create a new itinerary • ‘GET /itineraries‘ – Get user’s itineraries
Key Insight: The monolith is simple to build and deploy, but it has
significant limitations. You will experience these limitations first-hand
as you add features and users.
2 Challenges of the Monolith
During Phase 1, you will encounter several challenges:
Challenge Why It’s a Problem
Scalability You can only scale vertically (upgrading the
server). Horizontal scaling is impossible.
Failure A single bug can crash the entire application.
No isolation between services.
Deployment Every change requires redeploying the entire
application. High risk of downtime.
Data Storage JSON files are not designed for concurrent
access. No transactions, no indexing.
Team Collaboration All developers work on the same codebase.
Merge conflicts are frequent.
Testing Testing the entire application is slow. You
cannot test services independently.
Key Insight: The monolith is the ”good enough” starting point.
It allows you to build a working product quickly. However, as the
system grows, these challenges become unmanageable. The goal
of Phase 1 is to experience these challenges so you appreciate the
solutions introduced in later phases.
Deliverable: A working monolithic API with at least 5 endpoints,
deployed on a single server (local machine or VM).
Engr. Daniel Moune (ICT-U) CS 4122 77 / 84
Introduction - Why Distributed Systems
Distributed Systems - Models and Architectures
Cloud Models – IaaS, PaaS, SaaS Cloud Deployment Models – Public, Private, HCapstone Project – The Globetrotter Project Lab Setup – Setting up with DockePhase 1 – The Monolith
1 Architecture Overview
In Phase 1, you will build a monolithic application—a single server
handling all requests with data stored in a JSON file. This phase
demonstrates the limitations of centralized architectures and provides a baseline for comparison.
Architecture Diagram:
GlobeTrotter Monolith
API
Business Logic
Data Access
Client JSON File
Components:
• API Layer: REST endpoints for user registration, login,
destination search, itinerary management. • Business Logic: Algorithms for recommendations, trip
planning, and user preferences. • Data Access: Read and write to a JSON file (no database yet). • Authentication: Simple JWT-based authentication.
Technology Stack:
• Backend: Python (Flask or FastAPI) or Node.js (Ex- press) • Data: JSON file storage (no database) • Testing: pytest or Jest • Version Control: Git (each team creates a repository)
Endpoints to Implement:
• ‘POST /register‘ – Register a new user • ‘POST /login‘ – Authenticate a user • ‘GET /destinations‘ – Search destinations • ‘GET /recommendations‘ – Get personalized recommendations • ‘POST /itineraries‘ – Create a new itinerary • ‘GET /itineraries‘ – Get user’s itineraries
Key Insight: The monolith is simple to build and deploy, but it has
significant limitations. You will experience these limitations first-hand
as you add features and users.
2 Challenges of the Monolith
During Phase 1, you will encounter several challenges:
Challenge Why It’s a Problem
Scalability You can only scale vertically (upgrading the
server). Horizontal scaling is impossible.
Failure A single bug can crash the entire application.
No isolation between services.
Deployment Every change requires redeploying the entire
application. High risk of downtime.
Data Storage JSON files are not designed for concurrent
access. No transactions, no indexing.
Team Collaboration All developers work on the same codebase.
Merge conflicts are frequent.
Testing Testing the entire application is slow. You
cannot test services independently.
Key Insight: The monolith is the ”good enough” starting point.
It allows you to build a working product quickly. However, as the
system grows, these challenges become unmanageable. The goal
of Phase 1 is to experience these challenges so you appreciate the
solutions introduced in later phases.
Deliverable: A working monolithic API with at least 5 endpoints,
deployed on a single server (local machine or VM).
Engr. Daniel Moune (ICT-U) CS 4122 77 / 84
Introduction - Why Distributed Systems
Distributed Systems - Models and Architectures
Cloud Models – IaaS, PaaS, SaaS Cloud Deployment 