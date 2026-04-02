## Inspiration
Working as an EMT has allowed me to see how critical minutes are in an emergency and how systems can be optimized. Initial assessments take time, and in high-pressure situations—especially in mass casualty incidents, every second spent triaging, gathering vitals, or calling for additional resources can delay care. These small inefficiencies can have real consequences.

Because of this, we wanted to explore how the Presage SDK could be used to support first responders in those moments by providing faster insights and reducing communication delays. TriageLens is inspired by the idea that if we can streamline early assessment and make it easier to call for resources, responders can act faster and ultimately improve patient outcomes.

## What it does
TriageLens is a decision-support tool designed to help first responders move faster during patient assessment. Using camera-based sensing through the Presage SDK, the app provides, upon first contact, early estimates of vital signs such as heart rate and respiration before manual measurements are fully completed. This gives responders a quicker initial understanding of a patient’s condition and helps prioritize care.

The app also includes a simple triage system that classifies patients based on severity, allowing responders to quickly identify who needs immediate attention. In critical situations, TriageLens enables a one-tap dispatch alert that sends key information—such as location, estimated vitals, and severity—so additional resources can be requested without delaying care.

In mass casualty scenarios, the app provides a multi-patient view to help responders keep track of several individuals at once and prioritize effectively. It also includes an incident recording feature that allows interactions to be reviewed later for training and evaluation.

Overall, TriageLens is designed to support first responders by reducing delays in early assessment and communication, helping them act faster and more efficiently in high-pressure situations.

In an ideal world, every first responder would wear a camera enabled with our program, with hardware available we would have loved to attempt this as a hardware demo

## How we built it
We used Swift to develop our app. It includes a connection to the Presage SDK which is what is able to do our heart rate and blood pressure readings. Within Swift we have a different View Model for each of our different tabs, Live Assesment, Mass Casuality Mode, Escalate to Dispatch, Incident Logs, and a Training Review. When an unstable patient is detected, we have alerts that send a dispatch message for a first responder to attend to.


## Challenges we ran into
Cross platform development, since not everyone on the team had a mac. Used new technologies like the Presage SDK and we had to read documentation to finish on time. The integration of the Presage SDK took some time and there were challenges with accuracy.

## Accomplishments that we're proud of
We are proud to make something that helps first responders and the community navigate such a stressful situation more easily.

## What we learned
Building this project pushed us to work with real-time data and new technologies. Integrating the Presage SDK taught us how vital signs like heart rate and blood pressure are generated and handled in real time, and how to turn that data into meaningful alerts when a patient becomes unstable.

## What's next for TriageLens
In the future we hope to be able to integrate some hardware components with our app so that EMT's and other first responders are able to clip on a camera to their uniforms and recive this information for every scenario. Thus type of documentation protects both the person in the emergency and introduces a better form of accountability for the person responding to the emergency as well.

## Built With
Presage, Swift

## Edit: AthenaHacks 2026
Winner Best Hack by Bloomberg Engineering
Winner Best Overall
