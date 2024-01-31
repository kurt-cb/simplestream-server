
import dbus

try:
    #get the session bus
    bus = dbus.SessionBus()
    #get the object
    the_object = bus.get_object("org.simplestream.service", "/org/simplestream/service")
    #get the interface
    the_interface = dbus.Interface(the_object, "org.simplestream.service.Message")

    #call the methods and print the results
    reply = the_interface.file_update('test file.file')
    print(reply)

except BaseException as e:
    print("exception: %s" % e)
