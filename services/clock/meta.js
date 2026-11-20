// Describes the service, so a catalog can list it without opening the QML
// (decision 19.1). Depends on nothing from the real system — it's the
// service chosen for 0.502 precisely because it has no dependency to fake.
export default {
    service: "clock",
    title: "Clock",
};
